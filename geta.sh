#!/bin/bash

# add user
user=al
current_user=$(id -un)
sudo_group=sudo # only for debian

if ! id $user &> /dev/null; then
    sudo useradd -m -s /bin/bash $user
    sudo usermod -aG $sudo_group $user

    if [ -d ~/.ssh/ ]; then
        sudo cp ~/.ssh/  /home/$user/ -a
        sudo chown -R $user:$user /home/$user/.ssh
    fi
    echo $user:zee | sudo chpasswd
fi


if which git &> /dev/null; then
    git clone https://github.com/alzee/ash
else
    # get a.sh
    # Get tarball
    # https://unix.stackexchange.com/a/669552
    url=https://github.com/alzee/ash/archive/master.tar.gz
    f=ash-master.tar.gz
    curl -L -o $f "$url"
    tar xf $f && rm $f
    mv ${f%%.*} ash
fi

sudo sysctl -o ash/conf/templates/debian/z-sysctl.conf
sudo cp ash/conf/templates/debian/z-sysctl.conf /etc/sysctl.d/

echo $current_user > ash/init_user
sudo mv ash /home/$user/.ash
sudo chown -R $user:$user /home/$user/.ash
cd /home/$user
sudo -u $user .ash/a.sh -L
