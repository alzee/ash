#!/bin/bash
#
# vim:ft=sh

############### Variables ###############

############### Functions ###############

############### Main Part ###############

ibus-daemon -rxd

feh --bg-fill $bg

[ -f ~/.config/i3/startup.local.sh ] && . ~/.config/i3/startup.local.sh

#i3-msg workspace 1
i3-sensible-terminal
