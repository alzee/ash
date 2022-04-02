#!/bin/bash
#
# vim:ft=sh

############### Variables ###############

############### Functions ###############

############### Main Part ###############

ibus-daemon -rxd

feh --bg-fill ~/.config/i3/bg.png

[ -f ~/.config/i3/startup.local.sh ] && . ~/.config/i3/startup.local.sh

i3-sensible-terminal
