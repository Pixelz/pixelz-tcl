# coro-binds.tcl --
#
#     This script will cause every bound proc to be called as a coroutine.
#     To use, simply load this script before any others in eggdrop.
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

package require Tcl 8.6
package require eggdrop 1.6

if {[info commands EGGBIND] eq {}} { rename bind EGGBIND }
proc bind {type flags cmd/mask {procname {}}} {
	if {$procname eq {}} {
		# return any matching proc
		return [lrange {*}[EGGBIND $type $flags ${cmd/mask}] 1 end]
	} else {
		EGGBIND $type $flags ${cmd/mask} [list corowrap $procname]
		return
	}
}

proc corowrap {args} {
	coroutine [lindex $args 0][getid] {*}$args
	return
}

proc idgen {} {
	while {1} {
		yield [incr i]
	}
	return
}
if {[info commands getid] eq {}} { coroutine getid idgen }

putlog "Loaded coro-binds.tcl v1.0"