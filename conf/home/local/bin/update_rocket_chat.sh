#!/bin/bash
#
# vim:ft=sh

# Only for Debian
# https://docs.rocket.chat/quick-start/deploying-rocket.chat/other-deployment-methods/manual-installation/updating

sudo systemctl stop rocketchat

sudo rm -rf /opt/Rocket.Chat

sudo apt-get install -y build-essential graphicsmagick

# sudo n install 14.0.0
n install 14

#curl -L https://releases.rocket.chat/latest/download -o /tmp/rocket.chat.tgz
curl -L https://releases.rocket.chat/4.8.4/download -o /tmp/rocket.chat.tgz

tar -xzf /tmp/rocket.chat.tgz -C /tmp

cd /tmp/bundle/programs/server && npm install

sudo mv /tmp/bundle /opt/Rocket.Chat

sudo chown -R rocketchat:rocketchat /opt/Rocket.Chat

sudo systemctl start rocketchat
