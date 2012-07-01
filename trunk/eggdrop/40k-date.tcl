# 40kdate.tcl --
#
#     This script calculates warhammer 40k dates.
#
# Copyright (c) 2012, Rickard Utgren <rutgren@gmail.com>
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
# v1.0 by Pixelz (rutgren@gmail.com), July 1, 2012

package require Tcl 8.5
package require eggdrop 1.6

namespace eval ::40kdate {
	setudef flag 40kdate
}

# A year will be a leap year if it is divisible by 4 but not by 100.
# If a year is divisible by 4 and by 100, it is not a leap year unless it is also divisible by 400. 
proc ::40kdate::leap {year} {
	if {($year % 4) == 0} {
		# it is exactly devisable by 4
	
		if {($year % 100) == 0} {
			# it is exactly divisible by 100
			
			# is it also divisible by 400?
			if {($year % 400) == 0} {
				return 1
			} else {
				return 0
			}
		} else {
			# it is divisible by 4, but not by 100
			# it is a leap year
			return 1
		}
			
	} else {
		# it is not divisible by 4
		# it is not a leap year
		return 0
	}
}

# Returns the number of seconds in a year.
proc ::40kdate::year2sec {year} {
	if {[leap $year]} {
		return 31622400
	} else {
		return 31536000
	}
}

# Returns the unixtime at Jan 01, 00:00:00 UTC at any given year.
proc ::40kdate::year2unixtime {year} {
	clock add 0 [expr {$year - 1970}] years
}

proc ::40kdate::year2unixtime2 {year} {
	set currYear 1970
	set unixtime 0
	while {$currYear < $year} {
		incr unixtime [year2sec $currYear]
		incr currYear
	}
	return $unixtime
}

#Dates in the 40K universe use the format of: abbbccc.Mdd
#* a is an optional digit reflecting the date's accuracy
#* bbb are optional digits representing the "day" (see below)
#* ccc is the year
#* M is an abbreviation for Millennium
#* dd is the millennium

proc ::40kdate::decode {date} {
	if {![regexp -- {^(\d)?(\d{3})?(\d{3})\.M(\d{1,4})$} $date - accuracy day year millennium]} {
		return -code error "Invalid date format."
	} else {
		incr millennium -1
		set year ${millennium}${year}
		return [clock format [expr {[year2unixtime $year] + (([year2sec $year] / 1000) * $day)}] -timezone UTC]
	}
}

proc ::40kdate::encode {unixtime} {
	set year [clock format $unixtime -format %Y -timezone UTC]
	set millennium [string range $year 0 end-3]
	incr millennium
	set 40kyear [string range $year end-2 end]
	while {[string length $40kyear] < 3} { set 40kyear "0${40kyear}" }
	set days [expr {($unixtime - [year2unixtime $year]) / ([year2sec $year] / 1000)}]
	while {[string length $days] < 3} { set days "0${days}" }
	return "1${days}${40kyear}.M${millennium}"
}

proc ::40kdate::40k_pubm {nick uhost hand chan arg} {
	if {![channel get $chan 40kdate]} {
		return
	} else {
		lassign [split $arg] subCmd data
		switch -exact -nocase -- $subCmd {
			{} {
				putserv "PRIVMSG $chan :40K date: [::40kdate::encode [clock seconds]]"
			}
			encode {
				if {[string is digit $data]} {
					putserv "PRIVMSG $chan :40K date: [::40kdate::encode $data]"
				} else {
					puthelp "PRIVMSG $chan :Try !40kdate help"
				}
			}
			decode {
				if {![regexp -- {^(\d)?(\d{3})?(\d{3})\.M(\d{1,4})$} $data]} {
					putserv "PRIVMSG $chan :Invalid date format."
				} else {
					putserv "PRIVMSG $chan :[::40kdate::decode $data]"
				}
			}
			default {
				puthelp "PRIVMSG $chan :!40kdate [encode/decode] [unixtime/40kdate]"
			}
		}
	}
	return
}

namespace eval ::40kdate {
	bind pub - "!40kdate" ::40kdate::40k_pubm
	putlog "Loaded 40kdate v1.0 by Pixelz"
}