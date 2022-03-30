#!/bin/bash
#
# vim:ft=sh

############### Variables ###############

############### Functions ###############

############### Main Part ###############

ibus-daemon -rxd

feh --bg-fill $bg

touchpad=$(xinput --list --name-only | grep -i touchpad)
[ "$touchpad" ] &&
    xinput --set-prop "$touchpad" 'libinput Tapping Enabled' 1

# Why xinput not working if put it after i3-sensible-terminal?
lhand

[ -f ~/.config/i3/startup.local.sh ] && . ~/.config/i3/startup.local.sh

#i3-msg workspace 1
i3-sensible-terminal
