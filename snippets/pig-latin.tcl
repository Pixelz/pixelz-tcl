## pig latin
# http://users.snowcrest.net/donnelly/piglatin.html
# doesn't handle case
# punctuation, numerals and symbols are mostly untested and may break things.
# should treat hyphened words as separate words
# contractions (except for I'm, you'e, he's, she's etc) are untested
# correctly translates "qu" (e.g., ietquay instead of uietqay) 
# differentiates between "Y" as vowel and "Y" as consonant (e.g. yellow = elloyay and style = ylestay) — (except for possible exceptions when Y is a vovel but not the first letter in the word)

# pig latin is a one-way hash algoritm and can't be decoded
proc pig args {
	foreach w $args {
		if {[string match -nocase {[aeiou]*} $w]} {
			lappend o ${w}way
		} elseif {[regexp -nocase -- {((?:qu|y)*[^aeiouy]*)(.*)} $w - 1 2]} {
			lappend o ${2}${1}ay
		} else {
			lappend o $w
		}
	}
	puts unknown [join $o]
}


proc pig args { foreach w $args { if {[string match -nocase {[aeiou]*} $w]} { lappend o ${w}way } elseif {[regexp -nocase -- {((?:qu|y)*[^aeiouy]*)(.*)} $w - 1 2]} { lappend o ${2}${1}ay } else { lappend o $w } } ; puts unknown [join $o] }

## chefspeak
# issues: doesn't translate the same way as the first url. Problem with the python script I converted or problem with my own code?
#   I think the first URL uses some more advanced shit, my code should be consistant with the classic chef conversion
# http://www.cs.utexas.edu/~jbc/home/chef.html
# http://www.siafoo.net/snippet/133
#
# http://rinkworks.com/dialect/ (different conversion?)

proc chef {args} {
	set subs [list {a([nu])} {u\1}\
	{A([nu])} {U\1}\
	{a\Y} e\
	{A\Y} E\
	{en\y} ee\
	{\Yew} oo\
	{\Ye\y} e-a\
	{\ye} i\
	{\yE} I\
	{\Yf} ff\
	{\Yir} ur\
	{(\w+?)i(\w+?)$} {\1ee\2}\
	{\Yow} oo\
	{\yo} oo\
	{\yO} Oo\
	{^the$} zee\
	{^The$} Zee\
	{th\y} t\
	{\Ytion} shun\
	{\Yu} {oo}\
	{\YU} {Oo}\
	v f\
	V F\
	w w\
	W W\
	{([a-z])[.]} {\1. Bork Bork Bork!}]
	foreach word $args {
		foreach {exp subSpec} $subs {
			set word [regsub -all -- $exp $word $subSpec]
#			puts "$exp || $subSpec -> $word"
		}
		lappend retval $word
	}
	return [join $retval]
}

## elmer fudd
# http://www.cs.utexas.edu/~jbc/home/chef.html
# issues: none?
proc fudd {args} {
	set subs [list {[rl]} w\
	{[RL]} W\
	qu qw\
	Qu Qw\
	{th\y} f\
	{Th\y} F\
	th d\
	Th D\
	{n[.]} {n, uh-hah-hah-hah.}]
	foreach word $args {
		foreach {exp subSpec} $subs {
			set word [regsub -all -- $exp $word $subSpec]
		}
		lappend retval $word
	}
	return [join $retval]
}
 
