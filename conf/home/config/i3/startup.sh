#!/bin/bash
#
# vim:ft=sh

############### Variables ###############

############### Functions ###############

############### Main Part ###############

ibus-daemon -rxd

[ -f ~/.config/i3/startup.local.sh ] && . ~/.config/i3/startup.local.sh

feh --bg-fill $bg

#i3-msg workspace 1
i3-sensible-terminal

touchpad=$(xinput --list --name-only | grep -i touchpad)
[ "$touchpad" ] &&
    xinput --set-prop "$touchpad" 'libinput Tapping Enabled' 1
