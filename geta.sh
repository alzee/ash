#!/bin/bash

#DEFAULT_USER=

# add user
user=al
sudo_group=sudo

if ! id $user &> /dev/null; then
    sudo useradd -m -s /bin/bash $user
    sudo usermod -aG $sudo_group $user

    [ $DEFAULT_USER ] || DEFAULT_USER=$(id -un)

    if [ -d /home/$DEFAULT_USER/.ssh/ ]; then
        sudo cp /home/$DEFAULT_USER/.ssh/  /home/$user/ -a
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

cd /home/$user
sudo -u $user .ash/a.sh -L
sudo -u $DEFAULT_USER .ash/a.sh -Y
