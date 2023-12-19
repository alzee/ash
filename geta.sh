#!/bin/bash

# add user
user=al
sudo_group=sudo

if ! id $user &> /dev/null; then
    sudo useradd -m -s /bin/bash $user
    sudo usermod -aG $sudo_group $user

    # env DEFAULT_USER
    default_user=${DEFAULT_USER:-$(id -un)}
    default_user_home=/home/$default_user
    [ default_user = root ] && $default_user_home=/root

    if [ -d $default_user_home/.ssh/ ]; then
        sudo cp $default_user_home/.ssh/  /home/$user/ -a
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
sudo -u $default_user .ash/a.sh -Y
