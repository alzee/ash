#!/bin/bash

# add user
user=${MY_USER:-al} # env MY_USER
PASSWD=${PASSWD:-zee}
current_user=${DEFAULT_USER:-$(id -un)}
default_user=${DEFAULT_USER:-$current_user}
if ! id $default_user &> /dev/null; then
    default_user=$current_user
fi
sudo_group=sudo # only for debian

if ! id $user &> /dev/null; then
    sudo useradd -m -s /bin/bash $user
    sudo usermod -aG $sudo_group $user

    default_user_home=/home/$default_user
    [ $current_user = root ] && $default_user_home=/root

    if [ -d $default_user_home/.ssh/ ]; then
        sudo cp -a $default_user_home/.ssh/  /home/$user/
        sudo chown -R $user:$user /home/$user/.ssh
    fi
    sudo usermod --password $(openssl passwd -6 "$PASSWD") $user
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

echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/ip_forward.conf
sudo sysctl -p /etc/sysctl.d/ip_forward.conf

echo "default_user: $default_user" > ash/init_user
echo "current_user: $current_user" >> ash/init_user
echo "pwd: $PWD" >> ash/init_user

sudo mv ash /home/$user/.ash
sudo chown -R $user:$user /home/$user/.ash
cd /home/$user
sudo -u $user .ash/a.sh -L
