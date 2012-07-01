proc compareMasks {new old} {
	if {![string match -nocase $old $new]} {
		return 0
	} elseif {[string length [string map [set charMap [list "*" "" "?" ""]] $old]] > [string length [string map $charMap $new]]} {
		return 0
	} else {
		return 1
	}
}
