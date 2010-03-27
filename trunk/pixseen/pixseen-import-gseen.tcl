#!/bin/sh
# the next line restarts using tclsh \
exec tclsh8.5 "$0" "$@"

# RCS: $Id$
#
# ToDo:
# - initialize the db interface
# - define sql schema
# - verify sql schema
# - add chan2id stuff
# - add ircrfc stuff
# - close the db interface when done
# - fix FixMe's
# - check if we're being sourced from eggdrop, and if so, complain loudly

package require Tcl 8.5
package require sqlite3

if {$argv eq {}} {
	puts "Usage: $argv0 <filename>"
	exit
}
if {![file exists $argv]} {
	puts "No such file: $argv"
	exit
}

#define SEEN_JOIN 1
#define SEEN_PART 2
#define SEEN_SIGN 3
#define SEEN_NICK 4
#define SEEN_NCKF 5
#define SEEN_KICK 6
#define SEEN_SPLT 7
#define SEEN_REJN 8
#define SEEN_CHPT 9
#define SEEN_CHJN 10

#nick = newsplit(&s);
#host = newsplit(&s);
#chan = newsplit(&s);
#iType = atoi(newsplit(&s));
#when = (time_t) atoi(newsplit(&s));
#spent = atoi(newsplit(&s));
#msg = s;

set fd [open $argv r]
set events {}
while {![eof $fd]} {
	set line [gets $fd]
	if {[string index $line 0] ne {!}} { continue }
	lassign [set sline $sline] - nick uhost chan event timestamp spent
	set msg [lrange $sline  7 end]
	switch -exact -- $event {
		{1} {;# join
			if {[catch {seendb eval { INSERT OR REPLACE INTO seenTb VALUES(1, $nick, $uhost, $timestamp, chan2id($chan), NULL, NULL) }} error]} {
				puts stdout "SQL error: [seendb errorcode] $error"
				exit
			}
		}
		{2} {;# part
			if {[catch {seendb eval { INSERT OR REPLACE INTO seenTb VALUES(0, $nick, $uhost, $timestamp, chan2id($chan), $msg, NULL) }} error]} {
				puts stdout "SQL error: [seendb errorcode] $error"
				exit
			}
		}
		{3} {;# sign
			if {[catch {seendb eval { INSERT OR REPLACE INTO seenTb VALUES(4, $nick, $uhost, $timestamp, chan2id($chan), $msg, NULL) }} error]} {
				puts stdout "SQL error: [seendb errorcode] $error"
				exit
			}
		}
		{4} {;# nick
			if {[catch {seendb eval { INSERT OR REPLACE INTO seenTb VALUES(2, $nick, $uhost, $timestamp, chan2id($chan), NULL, $msg) }} error]} {
				puts stdout "SQL error: [seendb errorcode] $error"
				exit
			}
		}
		{5} {;# nckf
			if {[catch {seendb eval { INSERT OR REPLACE INTO seenTb VALUES(3, $nick, $uhost, $timestamp, chan2id($chan), NULL, $msg) }} error]} {
				puts stdout "SQL error: [seendb errorcode] $error"
				exit
			}
		}
		{6} {;# kick
			set aggressor [lindex $sline 7]
			set msg [lrange $sline 8 end]
			if {[catch {seendb eval { INSERT OR REPLACE INTO seenTb VALUES(7, $nick, $uhost, $timestamp, chan2id($chan), $msg, $aggressor) }} error]} {
				puts stdout "SQL error: [seendb errorcode] $error"
				exit
			}
		}
		{7} {;# splt
			if {[catch {seendb eval { INSERT OR REPLACE INTO seenTb VALUES(5, $nick, $uhost, $timestamp, chan2id($chan), NULL, NULL) }} error]} {
				puts stdout "SQL error: [seendb errorcode] $error"
				exit
			}
		}
		{8} {;# rejn
			if {[catch {seendb eval { INSERT OR REPLACE INTO seenTb VALUES(6, $nick, $uhost, $timestamp, chan2id($chan), NULL, NULL) }} error]} {
				puts stdout "SQL error: [seendb errorcode] $error"
				exit
			}
		}
		{9} {;# chpt
			# FixMe: figure out where/if botname is stored
			if {[catch {seendb eval { INSERT OR REPLACE INTO seenTb VALUES(11, $nick, $uhost, $timestamp, chan2id($chan), NULL, $botname) }} error]} {
				puts stdout "SQL error: [seendb errorcode] $error"
				exit
			}
		}
		{10} {;# chjn
			if {[catch {seendb eval { INSERT OR REPLACE INTO seenTb VALUES(10, $nick, $uhost, $timestamp, chan2id($chan), NULL, $botname) }} error]} {
				puts stdout "SQL error: [seendb errorcode] $error"
				exit
			}
		}
		default {
			puts stdout "UNHANDLED EVENT: $event"
			exit
		}
	}
}
close $fd
