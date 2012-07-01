# Web Enabled Tcl Oriented Regex Gathering And Scraping Machine

# Implement IDNA or steal implementation from http://svn.xmpp.ru/repos/tkabber/trunk/tkabber/idna.tcl

package require Tcl 8.5
package require eggdrop 1.8; # To hell with 1.6.x
package require http 2.5
package require htmlparse 1.1.3; #FixMe: figure out if this is the version we need

namespace eval ::wet::orgasm {
	namespace ensemble create -command orgasm -subcommands [list get] -map [dict create get FetchUrl]
	# These packages aren't hard requirements, so we check for them here instead of polluting the global namespace.
	# Check for the TLS package
	if {![catch {package require tls}]} {
		::http::register https 443 [list ::tls::socket -require 0 -request 1]
		set haveTls 1
		putlog {orgasm: TLS OpenSSL extension found, HTTPS available.}
	} else {
		set haveTls 0
		putlog {orgasm: TLS OpenSSL extension not found, HTTPS unavailable.}
	}
	
	# Check for zlib or Trf
	if {([lsearch -exact [info commands] zlib] != -1) || (![catch {package require zlib}])} {
		# we have zlib
		set haveGzip 1
		putlog {orgasm: zlib found, gzip compression availible.}
	} elseif {([lsearch -exact [info commands] zip] != -1) || (![catch {package require Trf}])} {
		# we have Trf
		set haveGzip 2
		putlog {orgasm: Trf found, gzip compression availible.}
	} else {
		set haveGzip 0
		putlog {orgasm: zlib or Trf not found, gzip compression unavailable.}
	}

	variable arrState; # state array
}

# fetches regular expressions from the central database for a particular site
# Returns: nested list of {re vars}
proc ::wet::orgasm::FetchRegex {site} {
	# FixMe: finish this proc
	# use gzip if available (zlib, trf)
	# use ssl if available (tls)
}

# Fetch a page. Handle cookies, referer, redirects, poisoning, gzip, ssl, more?
# Return: raw data
proc ::wet::orgasm::RecursiveGet {url {referer {}} {cookies {}} {traversals 0} {poison 0}} {
	# FixMe: finish this proc
	# Traversals = total number of redirects, no more than 10
	# Poison = redirects to same site, no more than 3
}

# http callback proc
proc ::wet::orgasm::HttpCallback {token} {
	upvar #0 $token state
	puts "httpCallback -> called with $token"
	coroget_[string trimleft $token ":htp"] [array get state]
	puts "httpCallback -> returning"
}

# Fetch a page and parse it
# Returns: nested list of {key value} pairs
proc ::wet::orgasm::FetchUrl {url} {
	# FixMe: finish this proc
	# FixMe: Translate IDNA domain
	
	#RecursiveGet $url
	
	# FixMe: Figure out charset
	
	puts "FetchUrl -> called"
	set token [::http::geturl $url -command [namespace current]::HttpCallback]
	coroutine coroget_[string trimleft $token ":htp"] coroget $token
	puts "FetchUrl -> returning"

	#FetchRegex site
	
	# FixMe: Parse page
	
	# FixMe: map HTML escapes
	
	# Return a nested list of {key value} pairs
	return [list]
}


proc coroget {token} {
	puts "coroget -> called with $token"
	puts "coroget -> waiting for httpCallback to complete"
	array set state [yield]
	puts "coroget -> back in coroget"
	puts "coroget -> state array: [array get state]"
	puts "coroget -> returning"
}




package provide ::wet::orgasm 0.1; # FixMe: is this where this line goes?
