#!/bin/bash
#
# vim:ft=sh

############### Variables ###############

############### Functions ###############

############### Main Part ###############

ibus-daemon -rxd

feh --bg-fill ~/.config/i3/bg.png

i3-sensible-terminal

# [ -f ~/.config/i3/startup.local.sh ] && . ~/.config/i3/startup.local.sh
