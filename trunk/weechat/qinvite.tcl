package require Tcl 8.5

if {![namespace exists ::weechat]} {
	puts "Please load this script from within weechat."
	exit 0
}

namespace eval ::weechat::script::qinvite {
	# Full host of the Q bot
	variable qHost {Q!TheQBot@CServe.quakenet.org}
	# Server name
	variable qServer {QuakeNet}
	
	variable initDone
}

proc ::weechat::script::qinvite::getServerBuffer {server} {
	return [weechat::buffer_search {irc} "server.$server"]
}

proc ::weechat::script::qinvite::signalHookCallback {data signal signalData} {
	variable qHost
	variable qServer
	# data: null
	# signal: EFnet,irc_in2_INVITE
	# signalData: {:bondi!pix@bondi.pix.pp.se INVITE Pixelz :#pix}
	#::weechat::print "" "args: $data <> $signal <> $signalData"
	
	set server [lindex [split $signal {,}] 0]
	lassign $signalData fullHost command subject channel
	set fullHost [string trimleft $fullHost {:}]
	set channel [string trimleft $channel {:}]
	#::weechat::print "" "$server <> $fullHost <> channel"
	
	if {[string equal -nocase $server $qServer] && $fullHost eq $qHost} {
		set serverBuffer [getServerBuffer $server]
		::weechat::print $serverBuffer "Auto-joining $channel"
		::weechat::command $serverBuffer "/join $channel"
	}
	
	return $::weechat::WEECHAT_RC_OK
}

proc ::weechat::script::qinvite::UNLOAD {args} {
	namespace forget ::weechat::script::qinvite
	return $::weechat::WEECHAT_RC_OK
}

# initialization
namespace eval ::weechat::script::qinvite {
	variable initDone

	#name: string, internal name of script
	#author: string, author name
	#version: string, script version
	#license: string, script license
	#description: string, short description of script
	#shutdown_function: string, name of function called when script is unloaded (optional)
	#charset: string, script charset (optional, if your script is UTF-8, you can use blank value here, because UTF-8 is default charset)
	#weechat::register "test_tcl" "FlashCode" "1.0" "GPL3" "Test script" "" ""
	::weechat::register "qinvite.tcl" "Pixelz" "0.1" "GPL3"\
			"Auto-join channels that Q invites you to." "::weechat::script::qinvite::UNLOAD" ""

	if {![info exists initDone]} {
			::weechat::hook_signal "*,irc_in2_invite" ::weechat::script::qinvite::signalHookCallback ""
			set initDone 1
	}
}