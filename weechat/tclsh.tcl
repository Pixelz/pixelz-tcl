# ToDo:
# - add /tclsh command that works like /shell
# - add command to re-open buffer?
# - reflected channels for stdin, stdout, stderr?

package require Tcl 8.5

if {![namespace exists ::weechat]} {
	puts "Please load this script from within weechat."
	exit 0
}

namespace eval ::weechat::script::tclsh {
	variable initDone
	variable bufferHand
}

# eval tcl commands and output to buffer
proc ::weechat::script::tclsh::eval_cmd {buffer command} {
	set errnum [catch { eval uplevel #0 {$command} } output]
	if {$output eq {}} { ::weechat::print $buffer "Tcl:" }
	foreach line [split $output "\n"] {
		if {![info exists prepend]} {
			if {$errnum > 0} {
				::weechat::print $buffer "Tcl error: $line"
			} else {
				::weechat::print $buffer "Tcl: $line"
			}
			set prepend 1
		} else {
			::weechat::print $buffer $line
		}
	}
	return
}

# callback for data received in input
proc ::weechat::script::tclsh::buffer_input_cb {data buffer input_data} {
	::weechat::print $buffer $input_data
	eval_cmd $buffer $input_data
	return $::weechat::WEECHAT_RC_OK
}

# callback called when buffer is closed
proc ::weechat::script::tclsh::buffer_close_cb {data buffer} {
	return $::weechat::WEECHAT_RC_OK
}

proc ::weechat::script::tclsh::UNLOAD {args} {
	namespace forget ::weechat::script::tclsh
	return $::weechat::WEECHAT_RC_OK
}

# callback for the /tclsh command
proc ::weechat::script::tclsh::tclsh_cb {data buffer args} {
	::weechat::print $buffer [join $args]
	eval_cmd $buffer [join $args]
	return $::weechat::WEECHAT_RC_OK
}

# initialization
namespace eval ::weechat::script::tclsh {
	variable initDone
	variable bufferHand

	#name: string, internal name of script
	#author: string, author name
	#version: string, script version
	#license: string, script license
	#description: string, short description of script
	#shutdown_function: string, name of function called when script is unloaded (optional)
	#charset: string, script charset (optional, if your script is UTF-8, you can use blank value here, because UTF-8 is default charset)
	#weechat::register "test_tcl" "FlashCode" "1.0" "GPL3" "Test script" "" ""
	::weechat::register "tclsh.tcl" "Pixelz" "0.1" "GPL3"\
		"adds an interactive tclsh" "::weechat::script::tclsh::UNLOAD" ""
	#FixMe: add charset?

	if {![info exists initDone]} {
		set bufferHand [::weechat::buffer_new "tclsh" "::weechat::script::tclsh::buffer_input_cb" "" "::weechat::script::tclsh::buffer_close_cb" ""]
		::weechat::buffer_set $bufferHand "title" "tclsh"
		::weechat::buffer_set $bufferHand "localvar_set_no_log" "1"
		::weechat::hook_command tclsh {evaluate Tcl code} {<code>} {} {} ::weechat::script::tclsh::tclsh_cb {}
		set initDone 1
	}
}
