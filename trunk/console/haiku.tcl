#!/bin/sh
# the next line restarts using tclsh \
exec tclsh "$0" "$@"

set a1 [list A The Some This That One]
set a2 [list white blue wet fall new big long green hard soft red short tall\
	great poor rich strong weak black hot cold dead sweet sour thin flat weak\
	mean spring deep dark light young old dry damp]
set a3 [list sound night god bird snow child car tomb bed guide fire bud desk\
	place death day frog cloud wind fog rain steel space man boy girl hat bag\
	flood void wife bed dream heart deer dog cat dove]
set a4 [list shivers. whispers. explodes. wonders. wanders. "is dead."\
	"goes up." "goes down." denies. destroys. demeans. shimmers. "is true."\
	"comes home." "goes away." "enters there." "swims away." "will turn."\
	pleases. lightens. darkens. rises. reasons. guesses. collides. listens.\
	"is born." softens. hardens. puzzles. "will fall." believes. dances. gazes.]

set b1 [list Cascading Unfolding Vibrating Flowering Devious Enveloped\
	Unfolding Generous Beauteous Collapsing Engulfing Determined Repulsive\
	Shadowy "Green plastic" Secretive Blossoming Immaculate Luminous Darkening\
	Lightening Delicate Forbidden Corroding Summery]
set b2 [list water snowfall beauty evening goddess raindrop petal heartache\
	friendship river mother father current nightfall husband shadow "deep crag"\
	winter summer lotus starfish lover system spirit "street light" evil music\
	laughter]
set b3 [list soars, lives, stares, grunts, dies, ends, chirps, sings, beats,\
	smears, cries, rocks, pants, shakes, runs, flows, drops, eats, chokes,\
	spreads, wounds, dives, stirs,]

set c1 [list A The This]
set c2 [list Death Laugh Shine Call Fall Hall Time Goal Scream Drink Item Leap\
	Sea Run Dream Break]
set c3 [list "into the light." "farther away." "nearer to me."\
	"across the wind." "burning with light." "under the waves."\
	"during the night." "into the dawn." "after sunset." "in winter chill."\
	"after the storm." "before twilight." "as light snow falls."\
	"out of our lives." "over the sky." "onto the bed." "through the window."\
	"after the bad." "to a new life." "without patience." "away from us."\
	"to escape death."]

proc lrandom {list} {
	lindex $list [expr { int(rand() * [llength $list]) }]
}

puts "[lrandom $a1] [lrandom $a2] [lrandom $a3] [lrandom $a4]"
puts "[lrandom $b1] [lrandom $b2] [lrandom $b3]"
puts "[lrandom $c1] [lrandom $c2] [lrandom $c3]"
