# % city2envtz "Europe/Stockholm"
# CEST-2
# % city2envtz "Europe/Sofia"
# EEST-3
# % city2envtz "America/Chicago"
# CDT+5

proc city2envtz {city} {
	set timezone [clock format [clock seconds] -format %Z -timezone $city]
	set offset [expr {[string range [clock format [clock seconds] -format %z -timezone $city] 0 2] * -1}]
	if {$offset > -1} { set offset "+${offset}" }
	return $timezone$offset
}


