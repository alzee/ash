#!/bin/bash
#
# vim:ft=sh

############### Variables ###############

############### Functions ###############

############### Main Part ###############

url=https://gitlab.com/alzee/ash/-/archive/master/ash-master.tar.gz
f=${url##*/}

curl -O "$url"

tar xf $f
mv ${f%%.*} .${f%-master*}
