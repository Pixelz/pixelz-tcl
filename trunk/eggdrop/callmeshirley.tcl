#!/bin/sh
# the next line restarts using tclsh \
exec tclsh "$0" "$@"

# Adapted to Tcl from http://orteil.dashnet.org/callmeshirley

namespace eval ::callmeshirley {
	setudef flag callmeshirley
	
	variable verbs [list "slap" "fuck" "spank" "smack" "pinch" "rub" "mock" "squeeze" "suck"\
		"bite" "bite off" "chew" "lick" "flap" "stroke" "touch" "smell" "sniff"\
		"jizz on" "rub one out on" "wank to" "shit on" "piss on" "paint" "fist"\
		"scratch" "screw" "kiss" "finger" "jiggle" "tickle" "hold" "grab" "blow on"\
		"scream at" "befriend" "write a book about" "sue" "marry" "rape"\
		"make love to" "pepper" "twist" "tenderize" "spit on" "fart on" "meet"\
		"spend a charming afternoon with" "introduce your sister to" "sandwich"\
		"write fanfic about" "blog about" "let's have a minute of silence for"\
		"listen to" "google" "stick your dick in" "prance around in"\
		"make your way inside" "plunder" "swiggity" "eat" "stuff" "hump"\
		"humiliate" "blow" "blow up" "fancy" "berate" "rate" "rustle"]
	
	variable nouns [list "tits" "ass" "dick" "mouth" "face" "balls" "cock" "crotch" "face"\
		"beard" "moustache" "buns" "boobs" "boobies" "breasts" "chest" "butt"\
		"buttocks" "nips" "nipples" "vag" "snatch" "cunt" "fanny" "skirt" "pants"\
		"panties" "loins" "undies" "bra" "shorts" "jimmies" "crack" "thighs" "rump"\
		"arse" "feet" "nuts" "cat" "horse" "goat" "dog" "parrot" "steak" "cheese"\
		"hose" "goatee" "sideburns" "sandwich" "booty" "mother" "father"\
		"grand-parents" "neighbor" "shiggity" "dinner" "shizzle" "bunny"\
		"evil twin" "thing" "pickle" "nutsack"]
	
	variable names [list "Shirley" "Sally" "Dolly" "Pedro" "Jose" "Juanita" "Sharon"\
		"Geoffrey" "Susan" "Mary" "Stanley" "Bradley" "Barney" "Brandon" "Milford"\
		"Robert" "Rosie" "Steve" "Patrick" "Jeffrey" "Brian" "David" "Santa"\
		"Batman" "mommy" "daddy" "grandpa" "grandma" "auntie" "uncle" "pretty"\
		"maybe" "when you're home" "when you're done" "darling" "fabulous"]
}

proc ::callmeshirley::lrandom list {
	[lindex $names [expr { int(rand() * [llength $names]) }]]
}

proc ::callmeshirley::generate {} {
	variable verbs
	variable nouns
	variable names
	return "Well [lindex $verbs [expr { int(rand() * [llength $verbs]) }]] my [lindex $nouns [expr { int(rand() * [llength $nouns]) }]] and call me [lindex $names [expr { int(rand() * [llength $names]) }]]."
}

proc ::callmeshirley::pubTrigger {nick uhost hand chan arg} {
	if {[channel get $chan callmeshirley]} {
		putserv "PRIVMSG $chan :[generate]"
	}
	return
}

namespace eval ::callmeshirley {
	bind pub - "!callmeshirley" ::callmeshirley::pubTrigger
}