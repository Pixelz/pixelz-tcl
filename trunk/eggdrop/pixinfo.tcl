# pixinfo.tcl --
#
#       SQLite powered info script.
#
# Copyright (c) 2010, Rickard Utgren <rutgren@gmail.com>
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
# RCS: $Id$
#
# v1.0 by Pixelz - April 5, 2010

# ToDo:
# !info add/learn <keyword> <definition>
# !info replace <keyword> <index> <definition>
# !info insert <keyword> <index> <definition>
# !info rem/remove/forget/del/delete <keyword> [index]
# !info lookup / ?? [-info] [-numbering on/off/1/0] <keyword> [target]
# !info search [-glob/-regex] [-key <keyword>] <definition>
# !info link <from keyword> <to keyword>
# !info trigger <trigger> [keyword] <-- not sure about this one, perhaps instead be able to set a key as "triggerable", or set all keys as triggerable
# !info move <from keyword> <from-index> <to-index> [to keyword]
# !info help
#
# handle ??keyword/?keyword/? keyword as well as ?? keyword
# lock/unlock/set access to definitions
# hide definitions - sent as notice only
# dynamic numbering of definitions, 1 item = no numbering, 2 or more = numbering < 10 = 1, 2, 3 > 10 = 01, 02 ...
# option to show total items in definition numbering, ie [1/3]
# per-channel databases, global database, ability to link channel databases together
# per-channel language
# per-channel access levels?
# dynamically settable access levels
# flood control
# some kind of trigger listing/searching
# simple web interface? use wub? http://gribble.dreamhosters.com/

#12:30:36 <+speechles> (01/03) .chanset #chan +dicm and .chattr handle +H
#12:30:39 <+speechles> it should look like this
#12:30:46 <+speechles> and allow direct indexing, or a range
#12:30:52 <+speechles> -> ?? whatever 1-3
#12:30:55 <+speechles> -> ?? whatever 3-1
#12:31:01 <+speechles> and know those are both the same range
#12:31:20 <+speechles> and it should know "start" and "end"
#12:31:26 <+speechles> as refering the first and last indexes

package require Tcl 8.5
package require msgcat 1.4.2
package require eggdrop 1.6
package require sqlite3

namespace eval ::pixinfo {
	# path to the database file
	variable dbfile {scripts/pixinfo.db}
	
	# Output with NOTICE nick (0) or PRIVMSG #chan (1)
	variable outnotc 1
	
	# Language
	variable defaultLang "en"
	
	## end of settings ##
	
	# list of locales, if you translate the script, add your translation to this list
	variable locales [list "en" "en_us_bork"]
	
	namespace import ::msgcat::*
	# mcload fails to load _all_ .msg files, so we have to do it manually
	foreach f [glob -directory [file join [file dirname [info script]] pixinfo-msgs] -type {b c f l} *.msg] {
		source -encoding {utf-8} $f
	}
	unset -nocomplain f
	
	mclocale $defaultLang
	setudef flag {info}
	setudef str {infolang}
	variable infover {1.0}
	variable dbVersion 1
}

# verifies table information, return 1 if it's valid, 0 if not
# FixMe: fix this proc
proc ::pixinfo::ValidTable {table data} {
	switch -exact -- $table {
		{pixinfo} {
			if {[join $data] eq {0 dbVersion INTEGER 1  0}} {
				return 1
			} else {
				return 0
			}
		}
		{infoTb} {
			if {[join $data] eq {0 event INTEGER 1  0 1 nick STRING 1  1 2 uhost STRING 1  0 3 time INTEGER 1  0 4 chanid INTEGER 0  0 5 reason STRING 0  0 6 othernick STRING 0  0}} {
				return 1
			} else {
				return 0
			}
		}
		{chanTb} {
			if {[join $data] eq {0 chanid INTEGER 1  1 1 chan STRING 1  0}} {
				return 1
			} else {
				return 0
			}
		}
		default {
			return 0
		}
	}
}

##
# infoTb
# keyId order definition nickId uhostId timestamp
# 
# keyTb
# keyId key isLink
#
# nickTb
# nickId nick
#
# uhostTb
# uhostId uhost

# Prepare the database on load
proc ::pixinfo::LOAD {args} {
	variable dbfile; variable dbVersion
	sqlite3 ::pixinfo::infodb $dbfile
	infodb collate IRCRFC ::pixinfo::rfccomp
	infodb function chan2id ::pixinfo::chan2id
	infodb function regexp ::pixinfo::pixregexp
	# turn on foreign keys
	if {[catch {infodb eval { PRAGMA foreign_keys = ON }} error]} {
		putlog [mc {%1$s SQL error %2$s; %3$s} {pixinfo.tcl} [infodb errorcode] $error]
		die [mc {Fatal Error!}]
	}
	
	if {[catch {set result [infodb eval {SELECT tbl_name FROM sqlite_master}]} error]} {
		putlog [mc {%1$s SQL error %2$s; %3$s} {pixinfo.tcl} [infodb errorcode] $error]
		die [mc {Fatal Error!}]
	} elseif {$result eq {}} {
		# there's no tables defined, so we define some
		putlog [mc {%s: No existing database found, defining SQL schema.} {pixinfo.tcl}]
		if {[catch {infodb eval {
			BEGIN TRANSACTION;
			
			-- Create a table and populate it with a version integer in case we need to change the schema in the future.
			CREATE TABLE pixinfo (
				dbVersion INTEGER UNIQUE NOT NULL
			);
			INSERT INTO pixinfo VALUES(1);
			
			-- Create the table that holds definitions
			CREATE TABLE infoTb (
				id INTEGER PRIMARY KEY UNIQUE NOT NULL,
				keyId INTEGER NOT NULL,
				order INTEGER NOT NULL,
				definition STRING NOT NULL,
				nickId INTEGER NOT NULL,
				uhostId INTEGER NOT NULL,
				timestamp INTEGER NOT NULL
			);
			
			-- Create the table that holds keys
			CREATE TABLE keyTb (
				id INTEGER PRIMARY KEY UNIQUE NOT NULL,
				key STRING UNIQUE NOT NULL
			);
			
			-- Create the table that holds nicks
			CREATE TABLE nickTb (
				id INTEGER PRIMARY KEY UNIQUE NOT NULL,
				nick STRING UNIQUE NOT NULL
			);
			
			-- Create the table that holds uhosts
			CREATE TABLE uhostTb (
				id INTEGER PRIMARY KEY UNIQUE NOT NULL,
				uhost STRING UNIQUE NOT NULL
			);
			
			-- Remove definitions if their key is deleted
			CREATE TRIGGER remove_definitions AFTER DELETE ON keyTb
			BEGIN
				DELETE FROM infoTb WHERE keyId = old.id;
			END;
			
			-- Remove childs if all of their parents are deleted
			CREATE TRIGGER remove_children AFTER DELETE on infoTb
			BEGIN
				-- remove keys
				DELETE FROM keyTb WHERE NOT EXISTS (SELECT keyId FROM infoTb WHERE keyId = old.keyId) AND id = old.keyId;
				-- remove nicks
				DELETE FROM nickTb WHERE NOT EXISTS (SELECT nickId FROM infoTb WHERE nickId = old.nickId) AND id = old.nickId;
				-- remove uhosts
				DELETE FROM uhostTb WHERE NOT EXISTS (SELECT uhostId FROM infoTb WHERE uhostId = old.uhostId) AND id = old.uhostId;
			END;
			
			COMMIT;
		}} error]} {
			putlog [mc {%1$s SQL error %2$s; %3$s} {pixinfo.tcl} [infodb errorcode] $error]
		}
	} else {
		# There's already data in this database, so we verify the schema
		# Verify the table names
		if {[catch { set result [infodb eval { SELECT tbl_name FROM sqlite_master WHERE type='table' ORDER BY tbl_name }] } error]} {
			putlog [mc {%1$s SQL error %2$s; %3$s} {pixinfo.tcl} [infodb errorcode] $error]
			die [mc {Fatal Error!}]
		} elseif {[join $result] ne {chanTb pixinfo infoTb}} {
			putlog [mc {%1$s: FATAL ERROR; SQLite database corrupt, exiting.} {pixinfo.tcl}]
			die [mc {Fatal Error!}]
			
		# Verify the pixinfo table
		} elseif {[catch { set result [infodb eval { PRAGMA table_info(pixinfo) }] } error]} {
			putlog [mc {%1$s SQL error %2$s; %3$s} {pixinfo.tcl} [infodb errorcode] $error]
			die [mc {Fatal Error!}]
		} elseif {![ValidTable {pixinfo} $result]} {
			putlog [mc {%1$s: FATAL ERROR; SQLite database corrupt, exiting.} {pixinfo.tcl}]
			die [mc {Fatal Error!}]
			
		# Verify the database version
		} elseif {[catch { set result [infodb eval { SELECT dbVersion FROM pixinfo LIMIT 1  }] } error]} {
			putlog [mc {%1$s SQL error %2$s; %3$s} {pixinfo.tcl} [infodb errorcode] $error]
			die [mc {Fatal Error!}]
		} elseif {$result != $dbVersion} {
			putlog [mc {%1$s: FATAL ERROR; SQLite database corrupt, exiting.} {pixinfo.tcl}]
			die [mc {Fatal Error!}]
			
		# Verify the infoTb table
		} elseif {[catch { set result [infodb eval { PRAGMA table_info(infoTb) }] } error]} {
			putlog [mc {%1$s SQL error %2$s; %3$s} {pixinfo.tcl} [infodb errorcode] $error]
			die [mc {Fatal Error!}]
		} elseif {![ValidTable {infoTb} $result]} {
			putlog [mc {%1$s: FATAL ERROR; SQLite database corrupt, exiting.} {pixinfo.tcl}]
			die [mc {Fatal Error!}]
			
		# Verify the chanTb table
		} elseif {[catch { set result [infodb eval { PRAGMA table_info(chanTb) }] } error]} {
			putlog [mc {%1$s SQL error %2$s; %3$s} {pixinfo.tcl} [infodb errorcode] $error]
			die [mc {Fatal Error!}]
		} elseif {![ValidTable {chanTb} $result]} {
			putlog [mc {%1$s: FATAL ERROR; SQLite database corrupt, exiting.} {pixinfo.tcl}]
			die [mc {Fatal Error!}]
			
		# Everything is OK!
		}  else {
			# Do some database maintenance
			dbCleanup
			putlog [mc {%s: Loaded the info database.} {pixinfo.tcl}]
		}
	}
	return
}

proc ::pixinfo::UNLOAD {args} {
	infodb close
	putlog [mc {%s: Unloaded the info database.} {pixinfo.tcl}]
	return
}

# We have to verify the password here to make sure that the die is successful
proc ::pixinfo::msg_die {cmdString op} {
	set hand [lindex $cmdString 3]
	set pass [lindex $cmdString 4 0]
	if {[passwdok $hand $pass]} {
		UNLOAD
	}
	return
}

# chanset wrapper
# checks the language people set and complains if it's not supported.
proc ::pixinfo::dcc_chanset {hand idx param} {
	set chan [lindex [set arg [split $param]] 0]
	if {![validchan $chan]} {
		*DCC:CHANSET $hand $idx $param
		return
	}
	set settings [lrange $arg 1 end]
	set found 0
	foreach setting $settings {
		if {$found} {
			set lang $setting
		} elseif {[string equal -nocase $setting {infolang}]} {
			set found 1
		}
	}
	if {[info exists lang] && ![validlang $lang]} {
		putdcc $idx [mc {Error: Invalid info language "%s".} $lang]
		return
	} else {
		::pixinfo::*DCC:CHANSET $hand $idx $param
		return
	}
}

# This proc will be renamed to ::*dcc:chanset on load. We call out real
# wrapper from here so that it can stay in the correct namespace
proc ::pixinfo::*dcc:chanset {hand idx param} {
	::pixinfo::dcc_chanset $hand $idx $param
}

namespace eval ::pixinfo {
	# trace die so that we can unload the database properly before the bot exist
	if {![info exists SetTraces]} {
		trace add execution die enter ::pixinfo::UNLOAD
		# don't try to trace these on Tcldrop
		if {![info exists ::tcldrop]} {
			trace add execution *dcc:die enter ::pixinfo::UNLOAD
			trace add execution *msg:die enter ::pixinfo::msg_die
			# wrap chanset so we can validate the language people set
			# FixMe: add Tcldrop equivalent
			rename ::*dcc:chanset ::pixinfo::*DCC:CHANSET
			rename ::pixinfo::*dcc:chanset ::*dcc:chanset
		}
		variable SetTraces 1
	}
	# load the database if it's not already loaded
	if {[info procs infodb] ne {infodb}} { ::pixinfo::LOAD }
	# unload the database on rehash & restart
	bind evnt - {prerehash} ::pixinfo::UNLOAD
	bind evnt - {prerestart} ::pixinfo::UNLOAD
	putlog [mc {Loaded %1$s v%2$s by %3$s} {pixinfo.tcl} $infover {Pixelz}]
}
