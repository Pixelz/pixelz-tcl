# casenick.tcl --
#
#     This script stops WeeChat from displaying nick changes that only
#     switch upper & lower case.
#
# Copyright (c) 2015, Rickard Utgren <rutgren@gmail.com>
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
# v1.0 by Pixelz (rutgren@gmail.com), March 7, 2015


package require Tcl 8.5

if {![namespace exists ::weechat]} {
        puts "Please load this script from within weechat."
        exit 0
}

namespace eval ::weechat::script::casenick {
        variable initDone
}

proc ::weechat::script::casenick::modifierHookCallback {data modifier modifierData string} {
    if {![string match "* is now known as *" $string]} {
	return $string
    } else {
	lassign [split $modifierData {;}] plugin bufferName tags
	if {$plugin eq {irc} && [lsearch [set tags [split $tags {,}]] {irc_nick}] != -1} {
	    foreach tag $tags {
		if {[string match "irc_nick1_*" $tag]} {
		    set nick1 [string range $tag 10 end]
		} elseif {[string match "irc_nick2_*" $tag]} {
		    set nick2 [string range $tag 10 end]
		}
	    }
	    if {![info exists nick1] || ![info exists nick2] || ![string equal -nocase $nick1 $nick2]} {
		return $string
	    } else {
		return
	    }
    	} else {
	    return $string
	}
    }
}

proc ::weechat::script::casenick::UNLOAD {args} {
        namespace forget ::weechat::script::casenick
        return $::weechat::WEECHAT_RC_OK
}

# initialization
namespace eval ::weechat::script::casenick {
        variable initDone
        variable bufferHand
        ::weechat::register "casenick.tcl" "Pixelz" "1.0" "ISC"\
                "stops weechat from displaying nick changes that only switch upper & lower case" "::weechat::script::casenick::UNLOAD" ""

        if {![info exists initDone]} {
                ::weechat::hook_modifier "weechat_print" ::weechat::script::casenick::modifierHookCallback ""
                set initDone 1
        }
}