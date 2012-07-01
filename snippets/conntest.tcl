#!/usr/bin/env tclsh8.6
# do what the fuck you want - licence

package require Tcl 8.6

proc sshdTest {hostList timeout} {
	set connectable [list]
	set unconnectable [list]
	foreach {host port} [split $hostList {: }] {
		set sock [socket -async $host $port]
		fileevent $sock writable [list [info coroutine] [list $sock $host $port open]]
		after $timeout catch [list [list [info coroutine] [list $sock $host $port closed]]]
		lassign [yield] sock host port state
		if {$state eq {open} && [fconfigure $sock -error] eq {}} {
			lappend connectable [join [list $host $port] {:}]
		} else {
			lappend unconnectable [join [list $host $port] {:}]
		}
		catch { close $sock }
	}
puts $connectable
	return [list $connectable $unconnectable]
}

proc doSshdTest {hostList {timeout {500}}} {
	lassign [sshdTest $hostList $timeout] connectable unconnectable
	if {$connectable ne {}} {
		puts "Connectable: [join $connectable {, }]"
	}
	if {$unconnectable ne {}} {
		puts "Unconnectable: [join $unconnectable {, }]"
	}
	exit 0
}

coroutine foo doSshdTest "google.com:80 yahoo.com:80"
vwait forever
