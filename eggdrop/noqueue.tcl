# noqueue.tcl --
#
#     This script makes Eggdrop send all commands to the IRC server
#     without delay. MAKE SURE that your bot is exempt from flood before
#     using.
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
# v1.0 by Pixelz (rutgren@gmail.com), July 8, 2010

package require Tcl 8.4
package require eggdrop 1.6.20

namespace eval ::noqueue {}

proc ::noqueue::out {queue text status} {
	if {$queue eq {noqueue}} {
		return
	} else {
		putnow $text
		return 1
	}
}

namespace eval ::noqueue {
	bind out - "% queued" ::noqueue::out
	putlog "Loaded noqueue.tcl v1.0 by Pixelz"
}
