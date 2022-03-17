#!/bin/bash
#
# vim:ft=sh

############### Variables ###############

############### Functions ###############

############### Main Part ###############

# url=https://github.com/alzee/ash/archive/refs/heads/master.zip
url=https://gitlab.com/alzee/ash/-/archive/master/ash-master.tar.gz
user=al
f=${url##*/}

# add user
sudo useradd -m -s /bin/bash $user
sudo usermod -aG sudo $user
sudo cp .ssh/  ~$user/ -a
sudo chown -R $user:$user ~$user/.ssh
echo $user:zee | sudo chpasswd

# get a.sh
curl -O "$url"
tar xf $f
rm $f
mv ${f%%.*} ~$user/.${f%-master*}
sudo chown  $user:$user ~$user/.${f%-master*}
