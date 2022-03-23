#!/bin/bash

# add user
user=al
sudo useradd -m -s /bin/bash $user
sudo usermod -aG sudo $user
sudo cp .ssh/  /home/$user/ -a
sudo chown -R $user:$user /home/$user/.ssh
echo $user:zee | sudo chpasswd

# get a.sh
#url=https://github.com/alzee/ash/archive/refs/heads/master.zip
url=https://gitlab.com/alzee/ash/-/archive/master/ash-master.tar.gz
f=${url##*/}
curl -O "$url"
tar xf $f
rm $f
sudo mv ${f%%.*} /home/$user/.${f%-master*}
sudo chown -R $user:$user /home/$user/.${f%-master*}
