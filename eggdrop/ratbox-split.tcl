# ratbox-split.tcl --
#
#     This script keeps track of netsplits on ircd-ratbox servers. The ircd has
#     to be configured so that the bot can see split/rejoin notices.
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
# v1.0 by Pixelz (rutgren@gmail.com), February 26, 2010

package require eggdrop 1.6
package require Tcl 8.5

namespace eval ::split {
	variable split
	setudef flag {split}
	setudef flag {splitannounce}
}

if {[info commands putraw] eq {}} {
	proc ::split::putraw {text} {
		append text "\n"
		putdccraw 0 [string length $text] $text
	}
}

proc ::split::shortduration {seconds} {
	# eggdrop doesn't actually report months, but we leave it here just in case
	# they decide to start doing that in the future
	set map [list \
		{ years} {y} \
		{ year} {y} \
		{ months} {m} \
		{ month} {m} \
		{ weeks} {w} \
		{ week} {w} \
		{ days} {d} \
		{ day} {d} \
		{ hours} {h} \
		{ hour} {h} \
		{ minutes} {m} \
		{ minute} {m} \
		{ seconds} {s} \
		{ second} {s} \
	]
	string map $map [duration $seconds]
}

proc ::split::raw_notc {from keyword text} {
	variable split
	if {$keyword ne {NOTICE}} {
		return
	} elseif {[string match {\* :\*\*\* Notice -- Server * split from *} $text] && [regexp -- {Notice -- Server ([^\s]+) split from ([^\s]+)} $text - splitServ fromServ]} {
		# a server split
		#putlog "$splitServ split from $fromServ"
		set split($splitServ) [list [clock seconds] $fromServ]
		foreach chan [channels] {
			if {[channel get $chan {splitannounce}]} {
				putraw "PRIVMSG $chan :Netsplit: $splitServ"
			}
		}
		return 1
	} elseif {[regexp -- {Notice -- Server ([^\s]+) being introduced by [^\s]+} $text - rejoinServ] || [regexp -- {Notice --  Link with ([^\s]+) established} $text - rejoinServ]} {
		# a server rejoined
		foreach chan [channels] {
			if {[channel get $chan {splitannounce}]} {
				if {[info exists split($rejoinServ)]} {
					putraw "PRIVMSG $chan :Rejoin: $rejoinServ split for: [duration [expr {[clock seconds] - [lindex $split($rejoinServ) 0]}]]"
				 } else {
					putraw "PRIVMSG $chan :Rejoin: $rejoinServ"
				 }
			}
		}
		unset -nocomplain split($rejoinServ)
		return 1
	} else {
		return
	}
}

proc ::split::pub_split {nick uhost hand chan arg} {
	variable split
	if {![channel get $chan {split}]} {
		return
	} elseif {[set servers [array names split]] eq {}} {
		putraw "PRIVMSG $chan :No servers are currently split."
		return
	} else {
		# calculate the length of the longest server name
		set longestServer 0
		foreach server $servers {
			if {[set len [string length $server]] > $longestServer} { set longestServer $len }
		}
		putraw "PRIVMSG $chan :Currently [llength $servers] servers are split:"
		foreach server $servers {
			set pad [expr {$longestServer - [string length $server]}]
			lassign $split($server) unixtime fromServ
			putraw "PRIVMSG $chan :$server[string repeat { } $pad] split [duration [expr {[clock seconds] - $unixtime}]] ago from $fromServ"
		}
		putraw "PRIVMSG $chan :End of split server list."
		return
	}
}

# FixMe: add timeout & implement this, do more checking than just connecting
proc ::split::TestConnection {host {port 6667}} {
	if {[catch {set sock [socket $host $port]} error]} {
		return $error
	} else {
		close $sock
		return
	}
}

namespace eval ::split {
	bind raw - {NOTICE} ::split::raw_notc
	bind pub - {!split} ::split::pub_split
	putlog {Loaded ratbox-split.tcl v1.0 by Pixelz}
}
