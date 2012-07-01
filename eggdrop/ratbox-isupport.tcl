# ratbox-isupport.tcl --
#
#     This checks isupport (raw 005) for a specific flag on all servers on the network
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

namespace eval ::isupport {
	# use /map (1) or /links (0)
	variable useMap 1
	variable inUse 0
	setudef flag {isupport}
}

if {[info commands putraw] eq {}} {
	proc ::isupport::putraw {text} {
		append text "\n"
		putdccraw 0 [string length $text] $text
	}
}

proc ::isupport::pub_isupport {nick uhost hand chan arg} {
	variable inUse; variable flag; variable target; variable servers; variable useMap
	if {![channel get $chan {isupport}]} {
		return
	} elseif {[llength [split $arg]] != 1} {
		putraw "PRIVMSG $chan :Usage: !isupport <flag>"
		return
	} elseif {$inUse} {
		return
	} else {
		set inUse 1
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

proc ::isupport::links_item {from keyword text} {
	variable inUse; variable servers
	if {$inUse} {
		lappend servers [lindex [split $text] 1]
	}
}

proc ::isupport::links_end {from keyword text} {
	variable inUse; variable servers
	if {$inUse} {
		foreach server $servers {
			putraw "VERSION $server"
		}
	}
}

proc ::isupport::map_item {from keyword text} {
	variable inUse; variable servers
	if {$inUse} {
		if {[regexp -all -line -- {^[^:]*:[\s`\-|]*([^\[]+).*$} $text - server]} {
			lappend servers $server
		}
	}
}

proc ::isupport::map_end {from keyword text} {
	variable inUse; variable servers
	if {$inUse} {
		foreach server $servers {
			putraw "VERSION $server"
		}
	}
}

proc ::isupport::calcLongestServer {servers} {
	set longestServer 0
	foreach server $servers {
		if {[set len [string length $server]] > $longestServer} { set longestServer $len }
	}
	return $longestServer
}

proc ::isupport::pad {server text} {
	variable servers; variable target
	# yeah yeah, I know it's expensive to run this for every server on the network but I don't care, cpu time is cheap
	set pad [expr {[calcLongestServer $servers] - [string length $server]}]
	putraw "PRIVMSG $target :$server[string repeat { } $pad] $text"
}

proc ::isupport::005 {from keyword text} {
	variable inUse; variable flag; variable target
	#CHANTYPES=&# EXCEPTS INVEX CHANMODES=eIb,k,l,imnpstSr CHANLIMIT=&#:100 PREFIX=(ov)@+ MAXLIST=beI:100 MODES=4 NETWORK=Textella KNOCK STATUSMSG=@+ CALLERID=g :are supported by this server
	#SAFELIST ELIST=U CASEMAPPING=rfc1459 CHARSET=ascii NICKLEN=10 CHANNELLEN=50 TOPICLEN=300 ETRACE CPRIVMSG CNOTICE DEAF=D MONITOR=100 :are supported by this server
	#FNC TARGMAX=NAMES:1,LIST:1,KICK:1,WHOIS:1,PRIVMSG:4,NOTICE:4,ACCEPT:,MONITOR: :are supported by this server
	foreach item [split $text] {
		lassign [split $item {=}] key value
		if {[string equal -nocase $flag $key]} {
			pad $from $item
		}
	}
	# FixMe: only unset this after _all_ servers are processed
	set inUse 0
}

namespace eval ::isupport {
	bind pub - "!isupport" ::isupport::pub_isupport
	bind raw - 364 ::isupport::links_item
	bind raw - 365 ::isupport::links_end
	bind raw - 015 ::isupport::map_item
	bind raw - 017 ::isupport::map_end
	bind raw - 105 ::isupport::005; #this is 005 for remote servers
	bind raw - 005 ::isupport::005
	putlog "Loaded ratbox-isupport.tcl v1.0 by Pixelz"
}
