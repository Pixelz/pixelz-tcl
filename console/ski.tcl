#!/bin/sh
# the next line restarts using tclsh \
exec tclsh "$0" "$@"

puts "Welcome to Night Skiing!"
puts "Use the A and D keys to steer"
puts ""
puts "Press enter to begin!"
gets stdin

puts -nonewline [exec stty raw -echo]
fconfigure stdin -buffering none -buffersize 1 -blocking 0

proc space {num} {
	string repeat " " $num
}

proc pos {num} {
	return "[space $num]H[space [expr {35 - $num}]]"
}

proc moveOffset {pos} {
	if {$pos <= 0} {
		return [incr pos]
	} elseif {$pos >= 42} {
		return [incr pos -1]
	} else {
		switch -- [expr int(rand()*5)] {
			0 - 1 { return [incr pos -1]}
			2 { return $pos }
			3 - 4 { return [incr pos] }
		}
	}
}

proc commify {number} {
	regsub -all \\d(?=(\\d{3})+([regexp -inline {\.\d*$} $number]$)) $number {\0,}
}

#<offset> <!> <space> <pos> <space> <!>
#   42     1     ?      1      ?     1

# "level" width: 38
# screen width: 80
# max offset = 80-38 = 42
proc ski {} {
	set offset 21
	set oldOffset 21
	set pos 19
	set skiing 1
	set yards 0
	while {$skiing} {
		if {$pos <= 0 || $pos >= 35} { set skiing 0; break }
		if {$oldOffset < $offset} {
			puts "[space $offset]\\[pos $pos]\\"
		} elseif {$oldOffset > $offset} {
			puts "[space $offset]/[pos $pos]/"
		} else {
			puts "[space $offset]|[pos $pos]|"
		}
		set newOffset [moveOffset $offset]
		incr pos [expr {($newOffset - $offset) * -1}]
		
		set in [read stdin 1]
		if {[string equal -nocase $in {a}]} {
			incr pos -1
		} elseif {[string equal -nocase $in {d}]} {
			incr pos 1
		}
		
		#incr pos [expr {int(rand()*2)?1:-1}]
		
		set oldOffset $offset
		set offset $newOffset
		incr skiing
		incr yards
		after 15
	}
	if {$pos < 10} {
		puts "[space $offset]*[pos $pos]!"
	} else {
		puts "[space $offset]![pos $pos]*"
	}
	puts ""
	puts "You skied a total of [commify $yards] yards!"
}

ski
exec stty sane
