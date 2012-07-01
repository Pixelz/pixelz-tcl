# ratbox-info.tcl --
#
#     This checks /info for a specific flag on all servers on the network
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
# v1.0 by Pixelz (rutgren@gmail.com), February 28, 2010

package require Tcl 8.5
package require eggdrop 1.6

namespace eval ::info {
	# use /map (1) or /links (0)
	variable useMap 1
	variable inUse 0
	variable sentHelpText 0
	setudef flag {info}
}

if {[info commands putraw] eq {}} {
	proc ::info::putraw {text} {
		append text "\n"
		putdccraw 0 [string length $text] $text
	}
}

proc ::info::pub_info {nick uhost hand chan arg} {
	variable inUse; variable flag; variable target; variable servers; variable useMap; variable sentHelpText
	if {![channel get $chan {info}]} {
		return
	} elseif {[llength [split $arg]] != 1} {
		putraw "PRIVMSG $chan :Usage: !info <flag>"
		return
	} elseif {$inUse} {
		return
	} else {
		set inUse 1
		set sentHelpText 0
		set flag $arg
		set target $chan
		set servers {}
		if {([info exists useMap]) && ($useMap == 1)} {
			putraw "MAP"
		} else {
			putraw "LINKS"
		}
	}
}

proc ::info::links_item {from keyword text} {
	variable inUse; variable servers
	if {$inUse} {
		lappend servers [lindex [split $text] 1]
	}
}

proc ::info::links_end {from keyword text} {
	variable inUse; variable servers
	if {$inUse} {
		foreach server $servers {
			putraw "INFO $server"
		}
	}
}

proc ::info::map_item {from keyword text} {
	variable inUse; variable servers
	if {$inUse} {
		if {[regexp -all -line -- {^[^:]*:[\s`\-|]*([^\[]+).*$} $text - server]} {
			lappend servers $server
		}
	}
}

proc ::info::map_end {from keyword text} {
	variable inUse; variable servers
	if {$inUse} {
		foreach server $servers {
			putraw "INFO $server"
		}
	}
}

proc ::info::calcLongestServer {servers} {
	set longestServer 0
	foreach server $servers {
		if {[set len [string length $server]] > $longestServer} { set longestServer $len }
	}
	return $longestServer
}

proc ::info::pad {server text} {
	variable servers; variable target
	# yeah yeah, I know it's expensive to run this for every server on the network but I don't care, cpu time is cheap
	set pad [expr {[calcLongestServer $servers] - [string length $server]}]
	putraw "PRIVMSG $target :$server[string repeat { } $pad] $text"
}

proc ::info::raw_371 {from keyword text} {
	variable inUse; variable flag; variable target; variable sentHelpText
	if {[regexp -nocase -- {^\S+\s:(\S+)\s*([^\[]+?)\s*\[(.+?)\s*\]$} $text - iflag ival itext]} {
		if {[string equal -nocase $flag $iflag]} {
			if {!$sentHelpText} {
				putraw "PRIVMSG $target :$flag \[${itext}\]"
				set sentHelpText 1
			}
			pad $from "$iflag $ival"
		}
	}
	# FixMe: only unset this after _all_ servers are processed
	set inUse 0
}

namespace eval ::info {
	bind pub - "!info" ::info::pub_info
	bind raw - 364 ::info::links_item
	bind raw - 365 ::info::links_end
	bind raw - 015 ::info::map_item
	bind raw - 017 ::info::map_end
	bind raw - 371 ::info::raw_371
	putlog "Loaded ratbox-info.tcl v1.0 by Pixelz"
}
