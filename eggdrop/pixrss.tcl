# pixrss.tcl --

# ToDo: crop title length

package require Tcl 8.5
package require tdom 0.8

namespace eval ::pixrss {
	setudef flag pixrss
}

# detect feed type and version
proc ::pixrss::detectFeedType {xml} {
	set doc [dom parse $xml]
	set root [$doc documentElement]
	switch -exact -- [$root nodeName] {
		rss {
			switch -exact -- [set ver [$root getAttribute version]] {
				0.91 {
					if {![catch { $doc systemId } systemId] && $systemId eq {http://my.netscape.com/publish/formats/rss-0.91.dtd}} {
						return "RSS 0.91 netscape"
					} else {
						return "RSS 0.91 userland"
					}
				}
				0.92 - 0.93 - 0.94 - 2.0 { return "RSS $ver" }
			}	
		}
		rdf:RDF - Channel - feed {
			switch -exact -- [$root getAttribute xmlns] {
				"http://channel.netscape.com/rdf/simple/0.9/" - "http://my.netscape.com/rdf/simple/0.9/" {
					return "RSS 0.90"
				}
				"http://purl.org/rss/1.0/" {
					return "RSS 1.0"
				}
				"http://purl.org/net/rss1.1#" {
					return "RSS 1.1"
				}
				"http://purl.org/atom/ns#" {
					return "Atom 0.3"
				}
				"http://www.w3.org/2005/Atom" {
					return "Atom 1.0"
				
				}
			}
		}
	}
	return
}

proc ::pixrss::parseFeed {xml} {
	if {[set version [detectFeedType $xml]] eq {}} {
		# FixMe: complain? try parsing anyway?
		return -code error "version not detected"
	} else {
		switch -exact -- $version {
			"RSS 0.90" - "RSS 1.0" {
				set doc [dom parse $xml]
				set root [$doc documentElement]
				
				set ns [[$root selectNodes //rdf:RDF] getAttribute xmlns]
				$doc selectNodesNamespace [list rdf $ns]
				
				set chantitle [[$root selectNodes //rdf:channel/rdf:title/text()] data]
				set title [[lindex [$root selectNodes //rdf:item/rdf:title/text()] 0] data]
				set link [[lindex [$root selectNodes //rdf:item/rdf:link/text()] 0] data]
				
				return [list $version $chantitle $title $link]
			}
			"RSS 0.91 netscape" - "RSS 0.91 userland" - "RSS 0.92" - "RSS 0.93" - "RSS 0.94" - "RSS 2.0" {
				set doc [dom parse $xml]
				set root [$doc documentElement]
				
				set chantitle [[$root selectNodes /rss/channel/title/text()] data]
				set title [[lindex [$root selectNodes /rss/channel/item/title/text()] 0] data]
				if {[$root selectNodes /rss/channel/item/link] ne {}} {
					set link [[lindex [$root selectNodes /rss/channel/item/link/text()] 0] data]
				} else {
					set link [[lindex [$root selectNodes /rss/channel/item/guid/text()] 0] data]
				}
				
				return [list $version $chantitle $title $link]
			}
			"RSS 1.1" {
				set doc [dom parse $xml]
				set root [$doc documentElement]
				
				set ns [$root getAttribute xmlns]
				$doc selectNodesNamespace [list rss $ns]
				
				set chantitle [[$root selectNodes /rss:Channel/rss:title/text()] data]
				set title [[lindex [$root selectNodes /rss:Channel/rss:items/rss:item/rss:title/text()] 0] data]
				set link [[lindex [$root selectNodes /rss:Channel/rss:items/rss:item/rss:link/text()] 0] data]
				
				return [list $version $chantitle $title $link]
			}
			"Atom 0.3" - "Atom 1.0" {
				set doc [dom parse $xml]
				set root [$doc documentElement]
				
				set ns [$root getAttribute xmlns]
				$doc selectNodesNamespace [list atom $ns]
				
				set chantitle [[$root selectNodes //atom:feed/atom:title/text()] data]
				set title [[lindex [$root selectNodes /atom:feed/atom:entry/atom:title/text()] 0] data]
				set link [[lindex [$root selectNodes /atom:feed/atom:entry/atom:link] 0] getAttribute href]
				
				return [list $version $chantitle $title $link]
			}
			default {
				# FixMe: putlog this instead
				return -code error "unhandled version $version"
			}
		}
	}
	return
}

proc ::pixrss::httpCallback {ircvars stateArray} {
	array set state $stateArray
	lassign $ircvars nick uhost hand chan arg
	if {[catch { parseFeed [string trimleft $state(body)] } result]} {
		putloglev 1 * "Error parsing $state(url): $result"
	} else {
		lassign $result version chantitle title link
		puthelp "PRIVMSG $chan :$version \[$chantitle\] $title - $link"
	}
}

proc ::pixrss::pubCallback {nick uhost hand chan arg} {
	if {![channel get $chan pixrss]} {
		return
	} elseif {$arg eq "test"} {
		# RSS 0.90
		::pixhttp::fetch "http://rss.slashdot.org/Slashdot/slashdotDevelopers/to" [list ::pixrss::httpCallback [list $nick $uhost $hand $chan $arg]]
		# RSS 0.91 userland
		::pixhttp::fetch "http://static.userland.com/gems/backend/sampleRss.xml" [list ::pixrss::httpCallback [list $nick $uhost $hand $chan $arg]]
		::pixhttp::fetch "http://www.newsisfree.com/HPE/xml/feeds/59/759.xml" [list ::pixrss::httpCallback [list $nick $uhost $hand $chan $arg]]
		::pixhttp::fetch "http://www.antisource.com/backend/sitenews.xml" [list ::pixrss::httpCallback [list $nick $uhost $hand $chan $arg]]
		# RSS 0.91 netscape
		::pixhttp::fetch "http://4dtoday.com/en/rss.xml" [list ::pixrss::httpCallback [list $nick $uhost $hand $chan $arg]]
		::pixhttp::fetch "http://www.webreference.com/webreference.rdf" [list ::pixrss::httpCallback [list $nick $uhost $hand $chan $arg]]
		::pixhttp::fetch "http://www.webdeveloper.com/webdeveloper.rdf" [list ::pixrss::httpCallback [list $nick $uhost $hand $chan $arg]]
		# RSS 0.92
		::pixhttp::fetch "http://www.eliegante.com/blog/?feed=rss" [list ::pixrss::httpCallback [list $nick $uhost $hand $chan $arg]];# <-- idiot
		# RSS 1.0
		::pixhttp::fetch "http://rss.slashdot.org/Slashdot/slashdot" [list ::pixrss::httpCallback [list $nick $uhost $hand $chan $arg]]
		::pixhttp::fetch "http://agora.ex.nii.ac.jp/digital-typhoon/rss/en.rdf" [list ::pixrss::httpCallback [list $nick $uhost $hand $chan $arg]]
		::pixhttp::fetch "http://stash.norml.org/feed/rdf" [list ::pixrss::httpCallback [list $nick $uhost $hand $chan $arg]]
		::pixhttp::fetch "http://bazaar.launchpad.net/~tsasaki99/lipot/feed/download/head:/rss1.0slashdot.xml-20090930221011-ifwqporrh87nbn9n-1/rss-1.0-slashdot.xml" [list ::pixrss::httpCallback [list $nick $uhost $hand $chan $arg]]
		# RSS 1.1
		::pixhttp::fetch "http://inamidst.com/rss1.1/example.rss" [list ::pixrss::httpCallback [list $nick $uhost $hand $chan $arg]]
		# RSS 2.0
		::pixhttp::fetch "http://news.google.it/?output=rss" [list ::pixrss::httpCallback [list $nick $uhost $hand $chan $arg]]
		::pixhttp::fetch "http://news.google.com/?output=rss&vanilla=0" [list ::pixrss::httpCallback [list $nick $uhost $hand $chan $arg]]
		::pixhttp::fetch "http://news.google.ru/?output=rss" [list ::pixrss::httpCallback [list $nick $uhost $hand $chan $arg]]
		::pixhttp::fetch "http://www.imaginascience.com/xml/rss.xml" [list ::pixrss::httpCallback [list $nick $uhost $hand $chan $arg]]
		::pixhttp::fetch "http://www.kvirc.net/rss.php" [list ::pixrss::httpCallback [list $nick $uhost $hand $chan $arg]]
		::pixhttp::fetch "http://static.userland.com/gems/backend/rssTwoExample2.xml" [list ::pixrss::httpCallback [list $nick $uhost $hand $chan $arg]]
		::pixhttp::fetch "http://www.apple.com/main/rss/hotnews/hotnews.rss" [list ::pixrss::httpCallback [list $nick $uhost $hand $chan $arg]]
		::pixhttp::fetch "http://feeds.slo-tech.com/ST-novice" [list ::pixrss::httpCallback [list $nick $uhost $hand $chan $arg]]
		::pixhttp::fetch "http://www.theregister.co.uk/headlines.rss" [list ::pixrss::httpCallback [list $nick $uhost $hand $chan $arg]]
		# Atom 0.3
		::pixhttp::fetch "http://bazaar.launchpad.net/~tsasaki99/lipot/feed/download/head:/atom0.3sample.xml-20090930234623-wolx1awoxj7cj7fv-1/atom-0.3-sample.xml" [list ::pixrss::httpCallback [list $nick $uhost $hand $chan $arg]]
		# Atom 1.0
		::pixhttp::fetch "http://www.heise.de/newsticker/heise-atom.xml" [list ::pixrss::httpCallback [list $nick $uhost $hand $chan $arg]]
		::pixhttp::fetch "http://www.cantoni.org/atom.xml" [list ::pixrss::httpCallback [list $nick $uhost $hand $chan $arg]]
		::pixhttp::fetch "http://freecode.com/?format=atom" [list ::pixrss::httpCallback [list $nick $uhost $hand $chan $arg]]
	} else {
		::pixhttp::fetch $arg [list ::pixrss::httpCallback [list $nick $uhost $hand $chan $arg]]
	}
}

namespace eval ::pixrss {
	bind pub - "!pixrss" ::pixrss::pubCallback
	putlog "Loaded pixrss.tcl v0.1"
}