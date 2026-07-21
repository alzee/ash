#!/bin/bash
#
# vim:ft=bash

if [ -z "$PASS" ]; then
    echo Usage: PASS=123456 '[U=jerry]' $(basename $0)
    exit
fi

u=${U:-$USER}
useradd $u
usermod -aG wheel $u
echo $PASS | passwd --stdin $u

echo Switching to user $u
su - $u

git clone https://g.itove.com/alzee/ash .ash
.ash/a.sh -L
