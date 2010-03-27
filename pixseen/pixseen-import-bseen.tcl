#!/bin/sh
# the next line restarts using tclsh \
exec tclsh8.5 "$0" "$@"

package require Tcl 8.5
#package require sqlite3

if {![file exists $argv]} {
	if {$argv eq {}} {
		puts "Usage: $argv0 <filename>"
	}
	puts "No such file: $argv"
	exit
}

set fd [open $argv r]
gets $fd

set events {}
while {![eof $fd]} {
	set line [gets $fd]
	lassign [split $line] nick uhost time event
	if {$event eq {quit}} { puts [join [join [lrange [split $line] 5 end]]] }
#	if {[lsearch -exact $events $event] == -1} {
#		lappend events $event
#		lappend lines $line
#	}
}

#foreach line $lines { puts $line }
close $fd

