proc awesome {s} {
	set pos 0
	foreach c [split $s {}] {
		if {$c eq { }} {
			lappend r { }
		} elseif {!($pos%2)} {
			lappend r \026${c}\026; incr pos
		} else {
			lappend r $c
			incr pos
		}
	}
	return [join $r {}]
}

proc rainbow {args} {
	array set col {0 04 1 07 2 08 3 09 4 03 5 10 6 11 7 12 8 02 9 06 10 13 11 05}
	set pos 0
	foreach c [split [join $args] {}] {
		if {$c eq { }} { append r { }; continue }
		append r "\003$col($pos)$c"
		if {$pos == 11} { set pos 0 } else { incr pos }
	}
	return $r\003
}
