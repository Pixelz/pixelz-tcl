#!/bin/sh
# the next line restarts using tclsh \
exec tclsh "$0" "$@"

proc tr { from to string } {
	set mapping [list]
	foreach c1 [trExpand $from] c2 [trExpand $to] {
		lappend mapping $c1 $c2
	}
	return [string map $mapping $string]
}

proc trExpand { chars } {
	set state noHyphen
	set result [list]
	foreach c [split $chars {}] {
		switch -exact -- $state {
			noHyphen {
				set lastChar $c
				lappend result $c
				set state wantHyphen
			}
			wantHyphen {
				if { [string equal - $c] } {
					set state sawHyphen
				} else {
					set lastChar $c
					lappend result $c
				}
			}
			sawHyphen {
				scan $lastChar %c from
				incr from
				scan $c %c to
				if { $from > $to } {
					error "$lastChar does not precede $c."
				}
				for { set i $from } { $i <= $to } { incr i } {
					lappend result [format %c $i]
				}
				set state noHyphen
			}
		}
	}
	if { [string equal sawHyphen $state] } {
		lappend result -
	}
	return $result
}

switch -exact -- [lindex $argv 0] {
	{-e} - {--encrypt} {
		while {[gets stdin line] >= 0} {
			set cyphertext $line
			set cyphertext [tr a-zA-Z n-za-mN-ZA-M $cyphertext]
			set cyphertext [tr a-zA-Z n-za-mN-ZA-M $cyphertext]
			set cyphertext [tr a-zA-Z n-za-mN-ZA-M $cyphertext]
			puts $cyphertext
		}
		exit 0
	}
	{-d} - {--decrypt} {
		while {[gets stdin line] >= 0} {
			set plaintext $line
			set plaintext [tr a-zA-Z n-za-mN-ZA-M $plaintext]
			set plaintext [tr a-zA-Z n-za-mN-ZA-M $plaintext]
			set plaintext [tr a-zA-Z n-za-mN-ZA-M $plaintext]
			puts $plaintext
		}
		exit 0
	}
	default {
		puts stderr "USAGE: 3rot13 -d | -e < infile > outfile"
		puts stderr "      3rot13 -e < in > out	# encrypt"
		puts stderr "      3rot13 -d < out > in	# decrypt"
		exit 1
	}
}
