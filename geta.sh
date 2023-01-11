#!/bin/bash

# add user
user=al
if ! id $user &> /dev/null; then
    sudo useradd -m -s /bin/bash $user
    sudo usermod -aG sudo $user
    if [ -d .ssh/ ]; then
        sudo cp .ssh/  /home/$user/ -a
        sudo chown -R $user:$user /home/$user/.ssh
    fi
    echo $user:zee | sudo chpasswd
fi


# get a.sh
# Get tarball
# https://unix.stackexchange.com/a/669552
url=https://github.com/alzee/ash/archive/master.tar.gz
f=ash-master.tar.gz
curl -L -o $f "$url"
tar xf $f && rm $f
mv ${f%%.*} ash

# Or using git
# git clone https://github.com/alzee/ash

sudo mv ash/ /home/$user/.ash
sudo chown -R $user:$user /home/$user/.ash
