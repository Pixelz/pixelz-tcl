# bitbucket.tcl --
#
#     This script fetches a changeset feed from bitbucket and displays
#     it in +bitbucket channels.
#
# Copyright (c) 2010-2011, Thomas Sader <thommey@gmail.com>
# Copyright (c) 2012, Rickard Utgren <rutgren@gmail.com>
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
# RCS: $Id$
#
# v1.0 by Pixelz (rutgren@gmail.com), July 3, 2012

package require eggdrop 1.6
package require Tcl 8.5
package require http 2.7
package require tls 1.6
package require tdom 0.8
package require htmlparse 1.2

namespace eval ::bitbucket {
	# feed url, include token if it's a private repository
	variable feedUrl "https://bitbucket.org/jespern/django-piston/rss"
	# repository name
	variable repoName "django-piston"
	# path to state file
	variable stateFile "scripts/bitbucket.state"

	# end of settings
	variable rssChecking
	variable lastCommit
	variable shortenState
	::http::register https 443 [list ::tls::socket -require 0 -request 1]
	setudef flag bitbucket
}

# spaghetti proc by thommey
proc ::bitbucket::getfilestr {filesdict {brace 0}} {
	putloglev d * [info level 0]
	# combine files in a dict
	set files [list]
	foreach k [dict keys $filesdict] {
		set subdict [dict get $filesdict $k]
		if {$subdict == 1} {
			lappend files $k
		} else {
			lappend files "\00310$k\003/[getfilestr $subdict 1]"
		}
	}
	if {[llength $files] > 1 && $brace} {
		return "([join [lsort $files]])"
	} else {
		return [join [lsort $files]]
	}
}

# callback for the rss http request
proc ::bitbucket::rssCallback {token} {
	variable rssChecking
	variable lastCommit
	putloglev d * [info level 0]
	upvar #0 $token state
	if {$state(status) ne {ok}} {
		putloglev d * "bitbucket.tcl http error: $state(status)"
	} elseif {[::http::ncode $token] != 200} {
		putloglev d * "bitbucket.tcl http error: [::http::ncode $token]"
	} else {
		# parse the xml
		set doc [dom parse $state(body)]
		set root [$doc documentElement]
		foreach item [$root selectNodes /rss/channel/item] {
			set title [string trim [[$item selectNodes title/text()] data]]
			set link [string trim [[$item selectNodes link/text()] data]]
			set description [::htmlparse::mapEscapes [[$item selectNodes description/text()] data]]
			set author [string trim [[$item selectNodes author/text()] data]]
			set unixtime [clock scan [set pubDate [string trim [[$item selectNodes pubDate/text()] data]]] -format "%a, %d %b %Y %T %z"]
			foreach {- file info} [regexp -all -inline -- {<li><a[^>]+>\s+([^<]+?)\s+</a>\(([^)]+)\)</li>} $description] {
				dict set files $file $info
			}
			putloglev d * "$title $unixtime $pubDate"
			if {![info exists lastCommit] || ([info exists lastCommit] && $unixtime > $lastCommit)} {
				if {![info exists lastCommit]} {
					putloglev d * "lastCommit doesn't exist"
				} else {
					putloglev d * "unixtime $unixtime > lastCommit $lastCommit"
				}
				if {![info exists currentHighestUnixtime] || ([info exists currentHighestUnixtime] && $unixtime > $currentHighestUnixtime)} {
					if {![info exists currentHighestUnixtime]} {
						putloglev d * "currentHighestUnixtime doesn't exist, setting to $unixtime"
					} else {
						putloglev d * "unixtime $unixtime > currentHighestUnixtime $currentHighestUnixtime"
					}
					set currentHighestUnixtime $unixtime
				}
				# format output					
				foreach file [dict keys $files] {
					dict set filesOutputDict {*}[split $file /] 1
				}
				set fileCountOutput "[set numFiles [llength [dict keys $files]]] [expr {$numFiles-1?"Files":"File"}]";#" <- syntax highlight fix
				# call the url shortener, and pass along output
				::bitbucket::shortenUrl $link [list $title $author $fileCountOutput [::bitbucket::getfilestr $filesOutputDict]]
			}
		}
		if {[info exists currentHighestUnixtime]} {
			putloglev d * "setting lastCommit to $currentHighestUnixtime"
			set lastCommit $currentHighestUnixtime
			saveState
		}
	}
	# clean up
	unset -nocomplain rssChecking
	catch { ::http::cleanup $token }
	return
}

# fetch the rss feed
proc ::bitbucket::getRss {args} {
	variable feedUrl
	variable rssChecking
	putloglev d * [info level 0]
	if {[info exists rssChecking]} {
		return
	} else {
		if {[catch {::http::geturl $feedUrl -timeout 10000 -command ::bitbucket::rssCallback} result]} {
			putloglev d * "bitbucket.tcl error while connecting to rss feed: $result"
		} else {
			set rssChecking 1
		}
	}
	return
}

# callback for the url shortener http request
proc ::bitbucket::shortenUrlCallback {token} {
	variable repoName
	variable shortenState
	putloglev d * [info level 0]
	lassign $shortenState($token) title author fileCountOutput filesOutput
	upvar #0 $token state
	if {$state(status) ne {ok}} {
		putloglev d * "bitbucket.tcl http error: $state(status)"
	} elseif {[::http::ncode $token] != 200} {
		putloglev d * "bitbucket.tcl http error: [::http::ncode $token]"
	} else {
		if {![string match "http://is.gd/*" [set shortUrl [string trim $state(body)]]]} {
			putloglev d * "bitbucket.tcl url shortening failed, body is not a url"
		} else {
			# announce new commits
			foreach chan [channels] {
				if {![channel get $chan bitbucket]} {
					continue
				} else {
					putserv "PRIVMSG $chan :Git commit (\00305${repoName}\003) by \00303${author}\003 ( \037\00307$shortUrl\003\037 ) \[$fileCountOutput $filesOutput\]"
					putserv "PRIVMSG $chan :`-- \002$title\002"
				}
			}
		}
	}
	# clean up
	unset -nocomplain shortenState($token)
	catch { ::http::cleanup $token }
	return
}

# shorten urls using is.gd
proc ::bitbucket::shortenUrl {url data} {
	variable shortenState
	putloglev d * [info level 0]
	if {[catch {::http::geturl "http://is.gd/create.php?[::http::formatQuery format simple url $url]" -timeout 10000 -command ::bitbucket::shortenUrlCallback} result]} {
		putloglev d * "bitbucket.tcl error while connecting to is.gd: $result"
	} else {
		set shortenState($result) $data
	}
	return
}

proc ::bitbucket::saveState {} {
	variable lastCommit
	variable stateFile
	putloglev d * [info level 0]
	if {[info exists lastCommit]} {
		putloglev d * "saving lastCommit $lastCommit on file"
		set fd [open $stateFile w]
		puts $fd $lastCommit
		close $fd
	}
	return
}

proc ::bitbucket::loadState {} {
	variable lastCommit
	variable stateFile
	putloglev d * [info level 0]
	if {[file exists $stateFile]} {
		set fd [open $stateFile r]
		set unixtime [string trim [read $fd]]
		close $fd
		if {[info exists lastCommit]} {
			putloglev d * "loadState: lastCommit: $lastCommit"
			if {$unixtime > $lastCommit} {
				putloglev d * "loadState: unixtime $unixtime > lastCommit $lastCommit"
				set lastCommit $unixtime
			}
		} else {
			set lastCommit $unixtime
		}
	}
	return
}

namespace eval ::bitbucket {
	loadState
	# check for new commits every 5 minutes
	bind time - "?0" ::bitbucket::getRss
	bind time - "?5" ::bitbucket::getRss
	putlog "Loaded bitbucket.tcl v1.0 by Pixelz"
}