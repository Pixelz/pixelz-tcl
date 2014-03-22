package require Tcl 8.5

if {![namespace exists ::weechat]} {
        puts "Please load this script from within weechat."
        exit 0
}

namespace eval ::weechat::script::casenick {
        variable initDone
}

proc ::weechat::script::casenick::modifierHookCallback {data modifier modifierData string} {
    if {![string match "* is now known as *" $string]} {
        return $string
    } else {
        lassign [split $modifierData {;}] plugin bufferName tags
        if {$plugin eq {irc} && [lsearch [set tags [split $tags {,}]] {irc_nick}] != -1} {
            # weechat_print <> xfer;irc_dcc.QuakeNet.veil;irc_privmsg,notify_private,prefix_nick_brown,nick_veil,log1 <> veil │ <Pixelz> herp is now known as derp
            # return ">>> $data <> $modifier <> $modifierData <> $string"
            # >>>  <> weechat_print <> irc;QuakeNet.#pixelz;irc_nick,irc_smart_filter,irc_nick1_veil,irc_nick2_Veil,log2

            # data: NULL
            # modifier: weechat_print
            # modifierData: irc;QuakeNet.#pixelz;irc_nick,irc_smart_filter,irc_nick1_veil,irc_nick2_Veil,log2
            # plugin: irc
            # bufferName: QuakeNet.#pixelz
            # tags: irc_nick,irc_smart_filter,irc_nick1_veil,irc_nick2_Veil,log2
            foreach tag $tags {
                if {[string match "irc_nick1_*" $tag]} {
                    set nick1 [string range $tag 10 end]
                } elseif {[string match "irc_nick2_*" $tag]} {
                    set nick2 [string range $tag 10 end]
                }
            }
            if {![info exists nick1] || ![info exists nick2] || ![string equal -nocase $nick1 $nick2]} {
                return $string
            } else {
                return
            }
        } else {
            return $string
        }
    }
}

proc ::weechat::script::casenick::UNLOAD {args} {
        namespace forget ::weechat::script::casenick
        return $::weechat::WEECHAT_RC_OK
}

# initialization
namespace eval ::weechat::script::casenick {
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
        ::weechat::register "casenick.tcl" "Pixelz" "0.1" "GPL3"\
                "stops weechat from displaying nick changes that only switch upper & lower case" "::weechat::script::casenick::UNLOAD" ""
        #FixMe: add charset?

        if {![info exists initDone]} {
                ::weechat::hook_modifier "weechat_print" ::weechat::script::casenick::modifierHookCallback ""
                set initDone 1
        }
}