# znc-autoop.tcl -- v1.0 by Pixelz (rutgren@gmail.com) June 10, 2009
#
# Usage: .chattr handle +Z [channel]
#        .aopkey <handle> [key/none]
#
# Copyright (c) 2009 Rickard Utgren
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# RCS: $Id$

package require eggdrop 1.6
package require Tcl 8.4

namespace eval zncAutoop {

	# .aopkey dcc command
	bind dcc - aopkey [namespace current]::dcc_aopkey
	proc dcc_aopkey {hand idx text} {
		set arg [split $text]
		#FixMe: figure out a way for channel owners/masters to be able to use this? Is that what we want?
		if {![matchattr $hand nm] || ![string equal -nocase $hand [lindex $arg 0]]} { return 0 }
		if {[llength $arg] == {0}} {
			putdcc $idx {Usage: aopkey <handle> [key/none]}
			return 0
		} elseif {[llength $arg] == {1}} {
			set target $text
			if {[validuser $target]} {
				set key [getuser $target xtra ZNCAOKEY]
				if {$key eq {}} { set key "not set" }
				putdcc $idx "Autoop key for ${target}: $key"
				return 1
			} else {
				putdcc $idx "No such user!"
				return 0
			}
		} else {
			set target [lindex $arg 0]
			set key [join [lrange $arg 1 end]]
			if {[validuser $target]} {
				if {[string tolower $key] eq "none"} { 
					setuser $target xtra ZNCAOKEY
					putdcc $idx "Removed Autoop key for $target."
				} else { 
					setuser $target xtra ZNCAOKEY $key
					putdcc $idx "Set Autoop key for $target to '$key'."
				}
				putcmdlog "#$hand# aopkey $target ..."
				return 0
			} else {
				putdcc $idx "No such user!"
				return 0
			}
		}
	}
	
	# challenge autoop users when they join a channel
	bind join Z|Z * [namespace current]::join_challenge
	proc join_challenge {nick uhost hand chan} {
		challengeTimeout
		variable challengeArray
		variable delayedChallenge
		set key [getuser $hand xtra ZNCAOKEY]
		if {$key eq {} || ![botisop $chan] || [isop $nick $chan] || [info exists challengeArray($nick)] || [info exists delayedChallenge($nick)] || [matchattr $hand dk|dk $chan]} {
			return 0
		} else {
			set aopDelay [channel get $chan "aop-delay"]
			set from [lindex $aopDelay 0]
			set to [lindex $aopDelay 1]
			if {$from < 5 || $to < 10} {
				set from 5
				set to 30
			}
			set delayedChallenge($nick) $nick
			utimer [randomDelay $from $to] "[namespace current]::delayed_Challenge [list $nick $uhost $hand]"
			return 0
		}
	}
	
	# send the delayed challenge
	proc delayed_Challenge {nick uhost hand} {
		variable challengeArray
		variable delayedChallenge
		if {$delayedChallenge($nick) ne $nick} {
			set nick $delayedChallenge($nick)
		}
		unset delayedChallenge($nick)
		set exit 1
		foreach {chan} [channels] {
			if {[onchan $nick $chan] && [botisop $chan] && ![isop $nick $chan] && [matchattr $hand o|o $chan] && ![matchattr $hand dk|dk $chan]} {
				set exit 0
				break
			}
		}
		if {$exit} { return 0 }
		set challenge [randomChallenge]
		putserv "NOTICE $nick :!ZNCAO CHALLENGE $challenge"
		set challengeArray($nick) [list $uhost $challenge [unixtime]]
		return 1
	}
	
	# verify the response we get from a challenge, and op the user
	bind notc Z|Z * [namespace current]::notc_gotResponse
	proc notc_gotResponse {nick uhost hand text dest} {
		challengeTimeout
		variable challengeArray
		set arg [split $text]
		if {![string equal -nocase $dest $::botnick] || [join [lrange $arg 0 1]] ne {!ZNCAO RESPONSE}} {
			return 0
		} else {
			if {![info exists challengeArray($nick)]} {
				putlog "znc-aop.tcl: \[${nick}!${uhost}\] sent an unchallenged response. This could be due to lag."
			} else {
				set oldUhost [lindex $challengeArray($nick) 0]
				if {$oldUhost ne $uhost} { 
					# hosts don't match, (should never happen?)
					putlog "znc-aop.tcl: host mismatch for $nick during challenge verification."
					return 0
				} else {
					set challenge [lindex $challengeArray($nick) 1]
					set response [lindex $arg 2]
					set key [getuser $hand xtra ZNCAOKEY]
					if {[md5 "${key}::${challenge}"] ne $response} {
						putlog "znc-aop.tcl: \[${nick}!${uhost}\] sent a bad response. Please verify that you have their correct password."
						return 0
					} else {
						foreach {chan} [channels] {
							if {[onchan $nick $chan] && [botisop $chan] && ![isop $nick $chan] && [matchattr $hand o|o $chan] && ![matchattr $hand dk|dk $chan]} {
								pushmode $chan +o $nick
							}
						}
						return 1
					}
				}
			}
		}
	}
	
	# answer challenges if all channels are synched
	bind notc Z|Z * [namespace current]::notc_answerChallenge
	proc notc_answerChallenge {nick uhost hand text dest} {
		set arg [split $text]
		if {![string equal -nocase $dest $::botnick] || [join [lrange $arg 0 1]] ne {!ZNCAO CHALLENGE}} {
			return 0
		}
		# check that all channels are synched
		set exit 0
		foreach {chan} [channels] {
			if {![info exists synchedChans($chan)]} {
				set exit 1
				break
			}
		}
		if {$exit} { return 0 }
		# check that we want ops in any channel where the challenge-issu-er has ops
		set exit 1
		foreach {chan} [channels] {
			if {[isop $nick $chan] && ![botisop $chan]} {
				set exit 0
				break
			}
		}
		if {$exit} { return 0 }
		set challenge [lindex $arg 2]
		set key [getuser $hand xtra ZNCAOKEY]
		if {$key eq {}} {
			putlog "znc-aop.tcl: Recieved challenge from $nick, but no key is set!"
			return 0
		} else {
			putquick "NOTICE $nick :!ZNCAO RESPONSE [md5 "${key}::${challenge}"]" -next
			return 1
		}
	}
	
	# answer challenges if any channel is desynched
	# FixMe: add stuff to some sort of queue and wait for the channel to synch instead of doing it like this
	bind notc - * [namespace current]::notc_answerChallengeDesynch
	proc notc_answerChallengeDesynch {nick uhost hand text dest} {
		set arg [split $text]
		if {![string equal -nocase $dest $::botnick] || [join [lrange $arg 0 1]] ne {!ZNCAO CHALLENGE}} {
			return 0
		}
		# check if any channel is desynched
		set exit 1
		foreach {chan} [channels] {
			if {![info exists synchedChans($chan)]} {
				set exit 0
				break
			}
		}
		if {$exit} { return 0 }
		set challenge [lindex $arg 2]
		set key [getuser $hand xtra ZNCAOKEY]
		if {$key eq {}} {
			putlog "znc-aop.tcl: Recieved challenge from $nick, but no key is set!"
			return 0
		} else {
			putquick "NOTICE $nick :!ZNCAO RESPONSE [md5 "${key}::${challenge}"]" -next
			return 1
		}
	}
	
	bind time - * [namespace current]::challengeTimeout
	proc challengeTimeout {args} {
		variable challengeArray
		set timeout 60
		foreach {nick} [array names challengeArray] {
			if {[expr {[unixtime]-[lindex $challengeArray($nick) 2] >= $timeout}]} {
				unset challengeArray($nick)
			}
		}
		return 0
	}
	
	# keep track of which channels are synched
	# 315 nick #chan :End of /WHO list.
	bind raw - 315 [namespace current]::synchChan_raw_315
	proc synchChan_raw_315 {from keyword text} {
		variable synchedChans
		if {$keyword ne 315} {
			return 0
		}
		set arg [split $text]
		set chan [lindex $arg 1]
		set synchedChans($chan) 1
		return 0
	}
	
	bind part - * [namespace current]::synchChan_part
	proc synchChan_part {nick uhost hand chan msg} {
		variable synchedChans
		if {$nick ne $::botnick} {
			return 0
		} else {
			unset synchedChans($chan)
		}
		return 0
	}
	
	bind evnt - connect-server [namespace current]::synchChan_evnt
	bind evnt - disconnect-server [namespace current]::synchChan_evnt
	proc synchChan_evnt {type} {
		variable synchedChans
		if {[array exists synchedChans]} {
			array unset synchedChans
		}
		return 0
	}
	
	# challenge / timeout array tracking procs
	#FixMe: add kick bind?
	bind nick Z|Z * [namespace current]::nick_trackChanges
	proc nick_trackChanges {nick uhost hand chan newnick} {
		variable challengeArray
		variable delayedChallenge
		if {[info exists challengeArray($nick)]} {
			set challengeArray($newnick) challengeArray($nick)
			unset challengeArray($nick)
		}
		foreach {item itemNick} [array get delayedChallenge] {
			if {$itemNick eq $nick} { set delayedChallenge($item) $newnick }
			break
		}
		return 0
	}
	
	bind part Z|Z * [namespace current]::part_trackChanges
	proc part_trackChanges {nick uhost hand chan msg} {
		variable challengeArray
		if {[info exists challengeArray($nick)] && ![onchan $nick]} {
			unset challengeArray($nick)
		}
		return 0
	}
	
	bind sign Z|Z * [namespace current]::sign_trackChanges
	proc sign_trackChanges {nick uhost hand chan reason} {
		variable challengeArray
		if {[info exists challengeArray($nick)]} {
			unset challengeArray($nick)
		}
		return 0
	}
	
	bind splt Z|Z * [namespace current]::splt_trackChanges
	proc splt_trackChanges {nick uhost hand chan} {
		variable challengeArray
		if {[info exists challengeArray($nick)]} {
			unset challengeArray($nick)
		}
		return 0
	}
	
	proc randomDelay {from to} {
		for {set i $from} {$i <= $to} {incr i} {
			lappend times $i
		}
		return [lindex $times [expr {int(rand()*[llength $times])}]]
	}

	 proc randomChallenge {} {
		set chars {abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!?.,:;/*-+_()}
		set range [expr {[string length $chars]-1}]
		set challenge {}
		for {set i 0} {$i < 32} {incr i} {
		   set pos [expr {int(rand()*$range)}]
		   append challenge [string range $chars $pos $pos]
		}
		return $challenge
	 }
	 
	putlog "Loaded znc-autoop.tcl v1.0 by Pixelz"
}
