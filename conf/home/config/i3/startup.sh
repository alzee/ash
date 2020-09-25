#!/bin/bash
#
# vim:ft=sh

############### Variables ###############

############### Functions ###############

############### Main Part ###############

ibus-daemon -rxd

[ -f ~/.config/i3/startup.local.sh ] && . ~/.config/i3/startup.local.sh

mon
