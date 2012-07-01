## ratbox-operbot.tcl --
#
# This script will op and invite IRC operators using knock and
# various commands described below.
#
# Copyright (c) 2009, Rickard Utgren <rutgren@gmail.com>
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
# v1.0 by Pixelz (rutgren@gmail.com) July 14, 2009

## Commands:
#
# Invite:
#   /knock #channel
#   /ctcp botnick INVITE #channel
#	/ctcp botnick INVITE (all channels)
# Op:
#	/ctcp botnick OP #channel
#	/ctcp botnick OP (all channels)
#	typing "operit" in a channel
#
# Autoop:
#   From the partyline: .chanset #chan +autoop-opers
#     Opers will be auto-opped when they join.
#     Keep in mind that if using this, the bot will /userhost everyone
#     that joins, so enabling putraw below is suggested and intended.

## Todo:
# - Remember who's an oper to lower server load. <-- add timestamp to an array of nicks, if timestamp is longer than 5 minutes or so, check again
#   - DON'T remember who's NOT an oper, they might oper up and the bot wouldn't work
# - Make putlogs better / remove them
# - fix FixMe's

namespace eval ::operbot {
	## Settings:

	# Output commands directly to the server, without using any queues?
	# The bot will need 'flood_exempt' or equivalent flags to not get flooded
	# off the server if this is enabled.
	set putraw 1

	## End of settings.
	package require eggdrop 1.6.0
	package require Tcl 8.5
	setudef flag {autoop-opers}
}

proc ::operbot::putraw {text} {
	variable putraw
	if {$putraw} {
		append text "\n"
		putdccraw 0 [string length $text] $text
	} else {
		putserv $text
	}
}

# autoop
proc ::operbot::join_autoop {nick uhost hand chan} {
	if {[channel get $chan {autoop-opers}] == 0} {
		return
	} else {
		variable a_op
		lappend a_op($nick) $chan
		putraw "USERHOST $nick"
	}
}

# public operit
proc ::operbot::pub_operit {nick uhost hand chan text} {
	variable a_op
	lappend a_op($nick) $chan
	putraw "USERHOST $nick"
	putlog "(${nick}!${uhost}) ![nick2hand $nick]! OPERIT $chan"
}

# ctcp op
proc ::operbot::ctcp_op {nick uhost hand dest keyword text} {
	variable a_op
	if {![isbotnick $dest]} { return 0 }
	if {$text eq {}} {
		set a_op($nick) "*"
		putraw "USERHOST $nick"
	} elseif {[validchan $text]} {
			lappend a_op($nick) $text
			putraw "USERHOST $nick"
	}
}

# ctcp invite
proc ::operbot::ctcp_invite {nick uhost hand dest keyword text} {
	variable a_invite
	if {![isbotnick $dest]} { return 0 }
	if {$text eq {}} {
		set a_invite($nick) "*"
		putraw "USERHOST $nick"
	} elseif {[validchan $text]} {
			lappend a_invite($nick) $text
			putraw "USERHOST $nick"
	}
}

# knock
proc ::operbot::raw_knock {from keyword text} {
	variable a_invite
	if {$keyword ne {710}} { return 0 }
	set x [string trim [string range $text 0 [expr {[string first {:} $text]-1}]]]
	set chan [lindex $x 1]
	set nuhost [lindex $x 2]
	set uhost [lindex [split $nuhost !] 1]
	set nick [lindex [split $nuhost {!}] 0]
	lappend a_invite($nick) $chan
	putraw "USERHOST $nick"
	putlog "(${nick}!${uhost}) ![nick2hand $nick]! KNOCK $chan"
}

## userhost reply
# <- :irc.stealth.no 302 Pixelz :saffron=+pix@yellowness. Pixelz*=+pix@127.0.0.1
# <nick>[*]=<+/-><uhost>
# * = oper
# + = not away
# - = away
proc ::operbot::rpl_userhost {from keyword text} {
	variable a_invite; variable a_op; variable putraw
	if {$keyword ne {302}} { return 0 }
	foreach mask [string range $text [split [expr {[string first : $text] + 1}]] end] {
		# user is an oper
		if {[string index [set nick [lindex [split $mask {=}] 0]] end] eq {*}} {
			set nick [string trimright $nick {*}]
			# op handling
			if {[info exists a_op($nick)]} {
				if {[lsearch -exact $a_op($nick) "*"] != -1} {
					foreach chan [channels] {
						if {[botisop $chan] && [onchan $nick $chan] && ![isop $nick $chan]} {
							putlog "operbot: $nick is an oper, giving channel ops on $chan"
							if {$putraw} { putraw "MODE $chan +o $nick"} else { pushmode $chan +o $nick }
						}
					}
				} else {
					foreach chan $a_op($nick) {
						if {[botisop $chan] && [onchan $nick $chan] && ![isop $nick $chan]} {
							putlog "operbot: $nick is an oper, giving channel ops on $chan"
							if {$putraw} { putraw "MODE $chan +o $nick"} else { pushmode $chan +o $nick }
						}
					}
				}
				unset a_op($nick)
			}
			# invite handling
			if {[info exists a_invite($nick)]} {
				if {[lsearch -exact $a_invite($nick) "*"] != -1} {
					foreach chan [channels] {
						# FixMe: filter out some channels in some intelligent way, like filter all +secret channels? add another setudef flag?
						# check that the channel is +i
						if {[lsearch -exact [split [string trimleft [lindex [split [getchanmode $chan]] 0] {+}] {}] {i}] != -1 && [botisop $chan] && ![onchan $nick $chan]} {
							putlog "operbot: $nick is an oper, inviting to $chan"
							putraw "INVITE $nick $chan"
						}
					}
				} else {
					foreach chan $a_invite($nick) {
						if {[botisop $chan] && ![onchan $nick $chan]} {
							putlog "operbot: $nick is an oper, inviting to $chan"
							putraw "INVITE $nick $chan"
						}
					}
				}
				unset a_invite($nick)
			}
		# user is not an oper
		} else {
			if {[info exists a_invite($nick)]} {
				putlog "operbot: $nick is NOT an oper, invite DENIED!"
				unset a_invite($nick)
			}
			if {[info exists a_op($nick)]} {
				#~ putlog "operbot: $nick is NOT an oper, channel ops DENIED!"
				unset a_op($nick)
			}
		}
	}
}

namespace eval ::operbot {
	bind join - * ::operbot::join_autoop
	bind pub - "operit" ::operbot::pub_operit
	bind ctcp - "OP" ::operbot::ctcp_op
	bind ctcp - "INVITE" ::operbot::ctcp_invite
	bind raw - 710 ::operbot::raw_knock
	bind raw - 302 ::operbot::rpl_userhost
	putlog "Loaded ratbox-operbot.tcl v1.0 by Pixelz"
}
