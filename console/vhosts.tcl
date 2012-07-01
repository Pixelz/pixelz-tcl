#!/bin/sh
# the next line restarts using tclsh \
exec tclsh8.5 "$0" "$@"

# add better formatting
# count number of resolving ips & number of unresolving ips

package require Tcl 8.5
package require dns
package require ip

set v4ignores [list "10.0.0.0/8" "172.16.0.0/12" "192.168.0.0/16" "169.254.0.0/16" "127.0.0.0/8"]
set v6ignores [list "::1/128" "fe80::/10"]

set data [exec ifconfig -a]

# sort the data
foreach {- addr length mask} [regexp -all -line -inline {inet6? addr: ?([^\s/]+)/?(\d+)?(?:.*?Mask: ?([^\s]+))?} $data] {
	if {$mask != {}} {
		lappend ipList [list $addr $mask]
	} else {
		lappend ipList [list $addr $length]
	}
}
if {![info exists ipList]} { exit }
set ipList [lsort -dictionary -unique $ipList]

foreach item $ipList {
	lassign $item addr masklen
	switch -- [::ip::version $addr] {
		{4} {
			foreach ignore $v4ignores {
				if {[::ip::equal $ignore $addr/[::ip::maskToLength $masklen -ipv4]]} {
					set continue 1
					break
				}
			}
			if {[info exists continue]} { unset continue; continue }
			# reverse lookup
			set tok [::dns::resolve $addr -type PTR]
			if {[::dns::status $tok] ne {ok}} {
				puts "$addr ->"
				continue
			}
			set PTR [::dns::name $tok]
			::dns::cleanup $tok
			# forward lookup
			set tok [::dns::resolve $PTR -type A]
			if {[::dns::status $tok] ne {ok}} {
				puts "$addr ->"
				continue
			}
			set A [::dns::name $tok]
			::dns::cleanup $tok
			# only output the host if reverse & forward lookups match
			if {[string equal -nocase $PTR $A]} {
				puts "$addr -> $A"
			} else {
				puts "$addr ->"
			}
			continue
		}
		{6} {
			if {[::ip::version [string trimleft $addr {:}]] == 4 && $masklen == 128} { continue }
			foreach ignore $v6ignores {
				if {[::ip::equal $ignore $addr/$masklen]} {
					set continue 1
					break
				}
			}
			if {[info exists continue]} { unset continue; continue }
			set arpa "[join [lreverse [split [string map {{:} {}} [::ip::normalize $addr]] {}]] .].ip6.arpa"
			# reverse lookup
			set tok [::dns::resolve $arpa -type PTR]
			if {[::dns::status $tok] ne {ok}} {
				puts "$addr ->"
				continue
			}
			set PTR [::dns::name $tok]
			::dns::cleanup $tok
			# forward lookup
			set tok [::dns::resolve $PTR -type AAAA]
			if {[::dns::status $tok] ne {ok}} {
				puts "$addr ->"
				continue
			}
			set AAAA [::dns::name $tok]
			::dns::cleanup $tok
			# only output the host if reverse & forward lookups match
			if {[string equal -nocase $PTR $AAAA]} {
				puts "$addr -> $AAAA"
			} else {
				puts "$addr ->"
			}
			continue
		}
		{0} - {default} { continue }
	}
}
