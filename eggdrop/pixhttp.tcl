# pixhttp.tcl --

# ToDo:
#	- support keep-alive, timeout after 115 seconds
#	- support chunked encoding

package require eggdrop 1.6
package require Tcl 8.4
package require tls 1.6
package require uri 1.2.2

namespace eval ::pixhttp {}

# socket readable fileevent, main connection handler
proc ::pixhttp::sockRead {stateArray} {
	array set state $stateArray
	if {[eof $state(sock)]} {
		{*}$state(callback) [array get state]
		close $state(sock)
		return
	} elseif {[catch {gets $state(sock) state(data)} error]} {
		putlog "pixhttp.tcl Error: $error"
		return
	} else {
		if {$state(gettingHeaders)} {
			if {$state(data) eq {}} {
				set state(gettingHeaders) 0
			} else {
				lappend state(headers) $state(data)
			}
		} else {
			append state(body) $state(data)
		}
		fileevent $state(sock) readable [list ::pixhttp::sockRead [array get state]]
		return
	}
}

# socket writeable fileevent, send initial commands
proc ::pixhttp::sockWrite {stateArray} {
	array set state $stateArray
	fileevent $state(sock) writable {}
	# upgrade the connection to SSL if we're using https
	if {$state(scheme) eq {https}} {
		tls::import $state(sock)
		fconfigure $state(sock) -buffering none -blocking 1
		tls::handshake $state(sock)
	}
	fconfigure $state(sock) -translation {auto crlf} -blocking 0 -buffering line
	puts $state(sock) "GET /${state(path)}?${state(query)} HTTP/1.0"
	puts $state(sock) "Host: $state(host)"
	puts $state(sock) "Connection: close"
	puts $state(sock) ""
	flush $state(sock)
	set state(gettingHeaders) 1
	fileevent $state(sock) readable [list ::pixhttp::sockRead [array get state]]
	return
}

# callback for async dns
proc ::pixhttp::fetchDnsCallback {ip host status stateArray} {
	array set state $stateArray
	set state(ip) $ip
	if {$status != 1} {
		putlog "pixhttp.tcl Error: DNS lookup for $host failed"
	} else {
		# connect to the site
		set state(sock) [socket -async $ip $state(port)]
		fconfigure $state(sock) -blocking 0 -buffering none
		fileevent $state(sock) writable [list ::pixhttp::sockWrite [array get state]]
	}
	return
}

# fetch an url, properly figure out encoding, redirects, cookies & all the rest of the crap
proc ::pixhttp::fetch {url callback} {
	# % uri::split "https://foo:bar@www.google.com:1234/dir/1/2/search.html?arg=0-a&arg1=1-b&arg3-c#hash"
	# fragment hash port 1234 path dir/1/2/search.html scheme https host www.google.com query arg=0-a&arg1=1-b&arg3-c pwd bar user foo
	# % uri::split "https://google.com"
	# fragment {} port {} path {} scheme https host google.com query {} pwd {} user {}
	array set state [::uri::split $url]
	set state(url) $url
	set state(callback) $callback
	if {$state(port) eq {}} {
		if {$state(scheme) eq {http}} {
			set state(port) 80
		} elseif {$state(scheme) eq {https}} {
			set state(port) 443
		}
	}
	if {$state(path) eq {}} { set state(path) {/}}
	if {($state(scheme) ne {http}) && ($state(scheme) ne {https})} {
		putlog "pixhttp.tcl Error: unknown uri scheme $state(scheme)"
	} else {
		# call async dns lookup
		# FixMe: don't dnslookup if we already know the IP address
		dnslookup $state(host) ::pixhttp::fetchDnsCallback [array get state]
	}
	return
}