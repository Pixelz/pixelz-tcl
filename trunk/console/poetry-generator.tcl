#!/bin/sh
# the next line restarts using tclsh \
exec tclsh "$0" "$@"

# concrete nouns
#set words(1) [list sea ship sail wind breeze wave cloud mast captain sailor shark wave tuna seashell pirate lad girl gull reef shore mainland moon sun]
set words(1) [list client eggdrop channel server op network bot topic service]
# abstract nouns
#set words(2) [list adventure courage endurance desolation death life love joy faith]
set words(2) [list action work noise death life love joy faith anger exhaustion]
# transitive verbs
#set words(3) [list command view lead pull love desire fight]
set words(3) [list kick deop ban join part quit netsplit grab fight]
# intransitive verbs
#set words(4) [list travel sail wave grow rise fall endure die]
set words(4) [list talk run stop eat grow work chat rise fall endure die]
# adjectives
#set words(5) [list big small old cold warm sunny rainy misty clear stormy rough lively dead]
set words(5) [list big small fast cold hot dead funny dark]
# adverbs
#set words(6) [list swiftly calmly quietly roughly]
set words(6) [list quickly loudly calmly quietly roughly eagerly easily patiently]
# injections
#set words(7) [list o oh ooh ah lord god wow "golly gosh"]
set words(7) [list oh ooh ah lord god damn wow lulz lol wtf]

set patterns [list\
	"The 5 1 6 3s the 1."\
	"5, 5 1s 6 3 a 5, 5 1."\
	"2 is a 5 1."\
	"7, 2!"\
	"1s 4!"\
	"The 1 4s like a 5 1."\
	"1s 4 like 5 1s."\
	"Why does the 1 4?"\
	"4 6 like a 5 1."\
	"2, 2, and 2."\
	"Where is the 5 1?"\
	"All 1s 3 5, 5 1s."\
	"Never 3 a 1."
]

proc lrandom {list} {
	lindex $list [expr { int(rand() * [llength $list]) }]
}

proc generatePoem {} {
	for {set x 0} {$x < [expr { int(rand()*4)+2 }]} {incr x} {
		lappend output [string toupper [subst [regsub -all -- {\d} [lrandom $::patterns] "\[lrandom \$::words(\\0)\]"]] 0 0]
	}
	return [join $output \n]
}

puts [generatePoem]
