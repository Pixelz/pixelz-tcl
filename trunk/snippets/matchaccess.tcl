package require Tcl 8.5

proc matchaccess {nick flags {channel {}}} {
	lassign [split $flags {|}] global local
	foreach f [split $global {}] {
		switch -exact -- $f {
			{@} {
				if {[isop $nick]} { return 1 }
			}
			{%} {
				if {[ishalfop $nick]} { return 1 }
			}
			{+} {
				if {[isvoice $nick]} { return 1 }
			}
			default {
				append globals $f
			}
		}
	}
	foreach f [split $local {}] {
		switch -exact -- $f {
			{@} {
				if {[validchan $channel] && [isop $nick $channel]} { return 1 }
			}
			{%} {
				if {[validchan $channel] && [ishalfop $nick $channel]} { return 1 }
			}
			{+} {
				if {[validchan $channel] && [isvoice $nick $channel]} { return 1 }
			}
			default {
				append locals $f
			}
		}
	}
	matchattr [nick2hand $nick] ${globals}|${locals} $channel
}
