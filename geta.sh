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
#url=https://github.com/alzee/ash/archive/refs/heads/master.zip
url=https://gitlab.com/alzee/ash/-/archive/master/ash-master.tar.gz
f=${url##*/}
curl -O "$url"
tar xf $f
rm $f
sudo mv ${f%%.*} /home/$user/.${f%-master*}
sudo chown -R $user:$user /home/$user/.${f%-master*}
