##!/bin/bash
#
# A script for quickly implementing softwares and settings after a Linux fresh installation. Mainly for Fedora semiannual upgrade purpose re-installation.

# TODO no sudos
#VARIANT_ID=workstation

############### Variables ###############
type dnf &> /dev/null && yum=dnf || yum=yum

user=zee
hostname=tes

# dir where this script in, no symbol link, so we don't need absolute path. Just don't cd to somewhere else.
scriptdir=$(dirname $0)

# which distro and version?
. /etc/os-release
distro=$ID
distro_ver=$VERSION_ID

############### Functions ###############

sudoer() {
	if ! id $user &> /dev/null ; then
		[ $UID -ne 0 ] && say "$0: Permission denied" && exit
		say user $user not exist, now creating...
		useradd -m $user -u 1000 -s /bin/bash || useradd -m $user -s /bin/bash	# debian need to specify shell
		#echo $user | sudo passwd --stdin $user # debian have no --stdin option
		echo $user:$user | sudo chpasswd
	fi

	say making $user sudoer...
	if [ "$distro" = debian ]; then
		sudo usermod -aG sudo $user
	else
		sudo usermod -aG wheel $user
	fi
	sudo cp $scriptdir/../conf/$distro/sudoer /etc/sudoers.d/
}

more_repo() {
	# TODO internet?
	#id $user &> /dev/null || { say user $user no exist, run $0 -s to create. ; exit; }
	[ "$UID" -eq 0 ] && say "DO NOT use root, assohole!" && exit

	say adding some repository...
	ilist="screen nginx nodejs vim ctags unzip curl"
	case $distro in
		fedora)
			sudo $yum install -y http://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm http://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm > /dev/null && say "rpmfusion repo installed" || say "rpmfusion repo install failed"
			# add chrome repo
			sudo cp $scriptdir/../conf/google-chrome.repo /etc/yum.repos.d/ && say "chrome repo installed" || say "chrome repo install failed"
			# add docker repo
			# sudo dnf -y install dnf-plugins-core
			sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
			php=$(echo php php-{common,cli,xml,gd,pdo,opcache,mbstring,mysqlnd,json,fpm,devel})
			ilist="$ilist i3 slock httpd mod_ssl mariadb-server $php git gcl ImageMagick nasm nmap samba postfix wireshark aircrack-ng libpcap-devel pixiewps irssi ansible nethack myman jq cmus whois transmission-common transmission-daemon libvirt qemu-kvm oathtool google-chrome-stable docker-ce mpv unrar"
			#xautolock arandr tlp id3v2 jmtpfs dnsmap dnsenum arp-scan macchanger xdotool testdisk sysstat ffmpeg virt-manager autoconf automake ctags dosemu obs-studio mplayer gimp blender dsniff ettercap driftnet reaver rdesktop chntpw gnome-tweaks qrencode zbar android-tools libnotify zenity wine-core wine-mono wine-common mingw64-wine-gecko mingw32-wine-gecko VirtualBox vlc
			rlist="tmux gnome-user-share gnome-initial-setup virtualbox-guest-additions simple-scan evolution-help evolution-ews evolution libreoffice-core libreoffice-ure libreoffice-data libreoffice-opensymbol-fonts bijiben rhythmbox shotwell transmission-gtk gnome-weather gnome-todo gnome-software orca empathy gnome-contacts gnome-maps gnome-calendar gnome-system-monitor gnome-disk-utility gnome-color-manager gedit devassistant-core gnome-boxes vinagre totem-nautilus totem cheese gnome-documents gnome-calculator file-roller baobab gnome-screenshot gnome-characters gnome-font-viewer setroubleshoot gnome-getting-started-docs gnome-shell-extension-background-logo gnome-user-docs gnome-logs yelp seahorse gnome-abrt abrt gnome-clocks firefox jwhois esmtp"
			# flatpak 
			;;
		rhel)
			sudo rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-$distro_ver.noarch.rpm
			;&
		centos)
			# The epel-release package is available from the CentOS Extras repository (enabled by default) and will be pulled in as a dependency of ius-release automatically
			sudo $yum install -y https://${distro}${distro_ver}.iuscommunity.org/ius-release.rpm

			#nic=$(nmcli d | grep ethernet | cut -d" " -f1)
			#sudo sed -i /ONBOOT/s/=.*/=yes/ /etc/sysconfig/network-scripts/ifcfg-$nic
			nmcli d connect $nic

			# TODO, version
			php=php72u
			php=$(echo $php $php-{common,cli,xml,gd,pdo,opcache,mbstring,mysqlnd,json,fpm,fpm-nginx} mod_$php)
			ilist="$ilist httpd24u httpd24u-mod_ssl $php mariadb101u-server git2u psmisc xz bzip2 bash-completion znc"
			rlist="mariadb-libs git"
			distro=rhel
			;;
		debian)
			yum=apt

			# add testing repo (latest packages)
			sudo sed -i '$adeb http://ftp.debian.org/debian testing main contrib non-free' /etc/apt/sources.list
			sudo sed -i '$adeb-src http://ftp.debian.org/debian testing main contrib non-free' /etc/apt/sources.list

			sudo $yum update -y

			php=$(apt list php -a | grep testing | cut -d':' -f2)
			php=php${php%+*}
			ilist="$ilist libapache2-mod-$php"
			php=$(echo $php-{common,cli,xml,gd,opcache,mbstring,zip,mysqlnd,curl,json,fpm,uploadprogress})
			ilist="$ilist apache2 $php mariadb-server git psmisc xz-utils bzip2 bash-completion man-db firewalld selinux-basics selinux-policy-default auditd znc"
			# apache2-dev libssl-dev libxml2-dev libcurl3-dev libpng-dev pkg-config lsb-release
			# Run selinux-activate(as root) to configure GRUB and PAM and to create /.autorelabel
			;;
	esac
}

# remove unneeded apps
rmapps() {
	[ $distro = debian ] && return
	say removing unneeded packages...
	for i in $rlist
	do
		rpm -q $i &> /dev/null && { sudo $yum remove -y $i > /dev/null && say "$i removed" || say "$i remove failed"; }
	done

	sudo $yum autoremove -y
	sudo $yum clean all # although debian don't have 'all'
}

# install necessary apps
inapps() {
	say updating...
	sudo $yum upgrade -y

	say installing packages...
	for i in $ilist
	do
		sudo $yum install -y $i > /dev/null && say "$i installed" || say "$i install failed"
	done
}

getcomposer(){
	# composer
	if [ ! -x ~/.local/bin/composer ];then
		say get composer...
		local a=composer-setup.php
		curl -L https://getcomposer.org/installer -o $a
		# TODO not return
		if echo -n $(curl -s https://composer.github.io/installer.sig) $a | sha384sum -c --status;then
			php $a && rm $a
			mkdir ~/.local/bin -p
			mv composer.phar ~/.local/bin/composer
			#composer config -g repo.packagist composer https://packagist.phpcomposer.com
			#composer config -g repo.packagist composer https?://packagist.org
		else
			say checksum fail!
		fi
	fi
}

addgrp() {
	# since we put web and mariadb dir in home
	sudo usermod -a -G $USER mysql && say added user mysql to group $USER
	case "$distro" in
		rhel | fedora)
			sudo usermod -a -G $USER apache && say added user apache to group $USER
			sudo usermod -a -G $USER nginx && say added user nginx to group $USER
			;;
		debian)
			sudo usermod -a -G $USER www-data && say added user www-data to group $USER
			;;
	esac
	sudo chmod 750 $HOME # 770 cause .ssh/authenticated fail since the permission is too open

	# add $USER into some groups
	# seems add to group kvm is not necessary
	[ $distro = fedora ] &&
		sudo usermod -a -G wireshark,docker,libvirt $USER && say "added $USER to wireshark,,docker,libvirt"
}

mysqldir(){
	# move mysql dir to home on fedora
	[ $distro != fedora ] && return
	# generate /var/lib/mysql/mysql.sock
	sudo systemctl restart mariadb
	say changing mysql datadir...

	local prefix=~/.mysql

	mkdir -p $prefix
	chcon -t mysqld_db_t $prefix
	sudo chown mysql:mysql $prefix

	# copy this line
	sudo sed -i "/^datadir/p" /etc/my.cnf.d/mariadb-server.cnf
	# prepend # to comment this line
	sudo sed -i "1,/^datadir/s/^datadir/#datadir/" /etc/my.cnf.d/mariadb-server.cnf
	sudo sed -i "/^datadir=/s:/.*:${prefix}/main:" /etc/my.cnf.d/mariadb-server.cnf
	# we better use the defaut mysql.sock path
	# copy this line
	#sudo sed -i "/^socket/p" /etc/my.cnf.d/mariadb-server.cnf
	# prepend # comment this line
	#sudo sed -i "1,/^socket/s/^socket/#socket/" /etc/my.cnf.d/mariadb-server.cnf
	#sudo sed -i "/^socket=/s:/.*:${prefix}/mysql.sock:" /etc/my.cnf.d/mariadb-server.cnf
	#sudo -u mysql mysql_install_db	# althought mysql_intall_db will do 'mkdir -p' ...

	sudo systemctl restart mariadb
	#mysql_secure_installation

}

# some gnome settings
gset() {
	[ $distro != fedora ] && return
	say some gnome settings...
	# the only one I have not found is "Don't suspend on lid close"
	sudo sed -i /HandleLidSwitch=/aHandleLidSwitch=ignore /etc/systemd/logind.conf
	#sudo sed -i /IgnoreLid=/s/false/true/ /etc/UPower/UPower.conf

	# disable all gnome extensions
	#gsettings set org.gnome.shell enabled-extensions "@as []"

	# get hidetopbar extension
	local a=~/.local/share/gnome-shell/extensions
	if [ ! -d "$a/hidetopbar@mathieu.bidon.ca" ];then
		mkdir -p $a
		git clone https://github.com/mlutfy/hidetopbar.git $a/hidetopbar@mathieu.bidon.ca
		pushd hidetopbar@mathieu.bidon.ca
		make schemas
		popd
	fi

	# enable extension alternatetab and hidetopbar
	gsettings set org.gnome.shell enabled-extensions "['alternate-tab@gnome-shell-extensions.gcampax.github.com', 'hidetopbar@mathieu.bidon.ca']"
	# Substitute Alt-Tab with a window based switcher that does not group by application.
	# 'thumbnail-only', 'app-icon-only' or 'both'
	gsettings set org.gnome.shell.window-switcher app-icon-mode both
	gsettings set org.gnome.shell.window-switcher current-workspace-only true

	# don't dim sreen when inactive
	gsettings set org.gnome.settings-daemon.plugins.power idle-dim false
	#gsettings set org.gnome.settings-daemon.plugins.power power-button-action suspend

	# show seconds in top bar clock
	gsettings set org.gnome.desktop.interface clock-show-seconds true
	gsettings set org.gnome.desktop.interface clock-format 12h
	#gsettings set org.gnome.desktop.interface clock-show-date true
	#gsettings set org.gnome.shell.calendar show-weekdate false

	# mouse & touchpad setting
	gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
	gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll false
	gsettings set org.gnome.desktop.peripherals.mouse natural-scroll false
	gsettings set org.gnome.desktop.peripherals.mouse left-handed true
	#gsettings set org.gnome.desktop.interface show-battery-percentage true
	#gsettings set org.gnome.desktop.interface enable-animations true

	# don't automount
	gsettings set org.gnome.desktop.media-handling automount false

	# don't show menubar for gnome-terminal
	gsettings set org.gnome.Terminal.Legacy.Settings default-show-menubar false

	# don't automaticly lock screen
	gsettings set org.gnome.desktop.screensaver lock-enabled false

	# don't dim when idle
	gsettings set org.gnome.settings-daemon.plugins.power idle-dim false

	# get default profile id
	local id schema
	id=$(gsettings get org.gnome.Terminal.ProfilesList default)
	id=${id:1:-1}	# remove single quotes
	schema=org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${id}/

	gsettings set $schema scrollbar-policy never
	gsettings set $schema use-theme-colors false
	gsettings set $schema use-transparent-background true
	gsettings set $schema background-transparency-percent 25
	gsettings set $schema audible-bell false
	gsettings set $schema foreground-color 'rgb(0,255,0)'
	gsettings set $schema background-color 'rgb(0,0,0)'

	# change background and screensaver pic. aha, too trivial, I choose set it using gui :(
	#gsettings get org.gnome.desktop.screensaver picture-uri 'file:////usr/share/gnome-control-center/pixmaps/noise-texture-light.png'

}

sethostname(){
	# set hostname
	say changing hostname to $hostname
	sudo hostname $hostname
	sudo sed -i s/.*/$hostname/ /etc/hostname

	# add hostname to /etc/hosts
	say add hostname to /etc/hosts
	if ! grep -wq `hostname` /etc/hosts; then
		sudo sed -i \$a"127.0.0.1 `hostname`" /etc/hosts
	fi
}

settimezone(){
	# timezone
	local tz
	tz=$(date +%Z)
	if [ "$tz" != CST ];then
		say set timezone to Asia/Shanghai
		sudo ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	fi
}

dir_struct(){
	[ $UID -eq 0 ] && exit

	# dir structures
	mkdir -p ~/{w,.local/bin,.vim/{map,session,template,undo},.sec,.screenlayout,.gpg,.config/{autostart,i3,mpv,cmus}}
	#chown -R $USER:$USER ~/{.local,.vim,.sec,.gpg}

	rmdir ~/{Downloads,Documents,Pictures,Music,Videos,Desktop,Public,Templates} 2>/dev/null
	#[ -d ~/Downloads ] && mv ~/{Downloads,l}
	#[ -d ~/Documents ] && mv ~/{Documents,d}
	#[ -d ~/Pictures ] && mv ~/{Pictures,p}
	#[ -d ~/Music ] && mv ~/{Music,m}
	#[ -d ~/Videos ] && mv ~/{Videos,v} && mv ~/v ~/m
}

mod_bashrc(){
	# source env,fun,ali in ~/.bashrc
	for i in env fun ali
	do
		grep -qw "~/.$i" ~/.bashrc || echo "[ -f ~/.$i ] && . ~/.$i" >> ~/.bashrc
		#[ -f ~/.$i ] && . ~/.$i
	done

	# stty -ixon in ~/.bashrc
	grep -qw 'ixon' ~/.bashrc || echo 'stty -ixon' >> ~/.bashrc
}

default_pool(){
	[ "$distro" != fedora ] && return
	# change libvirt default storage pool
	# https://serverfault.com/questions/840519/how-to-change-the-default-storage-pool-from-libvirt
	sudo virsh pool-destroy default
	sudo virsh pool-undefine default
	sudo virsh pool-define-as --name default --type dir --target ~/.vm
	sudo virsh pool-autostart default
}

# create some customized scripts and confs
misc() {
	[ "$distro" = rhel ] && sudo systemctl enable httpd mariadb
	# debian will auto start and enable apache2 and mariadb-server

	if [ "$distro" = debian ]; then
		# enable rewrite module
		sudo ln -s ../mods-available/rewrite.load /etc/apache2/mods-enabled/
		# enable mod_ssl
		sudo ln -s ../mods-available/ssl.load /etc/apache2/mods-enabled/
		sudo ln -s ../mods-available/ssl.conf /etc/apache2/mods-enabled/
		sudo ln -s ../mods-available/socache_shmcb.load /etc/apache2/mods-enabled/

		sudo ln -s ~/vhosts /etc/apache2/sites-enabled/
		sudo ln -s ~/vhosts.conf /etc/apache2/conf-enabled/

		# use mysql native password insead of system user credentials
		sudo mysql -e "use mysql; UPDATE user SET plugin='mysql_native_password' WHERE User='root'"
		sudo mysql -e "FLUSH PRIVILEGES"

		sudo systemctl stop nginx
		sudo systemctl disable nginx

		# debain default using dash, change to bash
		sudo ln -sf bash /bin/sh
	fi

	if [ "$distro" = fedora ]; then
		sudo firewall-cmd --add-service samba
		sudo firewall-cmd --remove-service ssh
		sudo systemctl disable libvirtd cups.socket
		sudo systemctl mask bluetooth
		# docker daemon config
		sudo systemctl start docker	# start docker to initialize /etc/docker/
		sudo cp $scriptdir/../conf/daemon.json /etc/docker/
		# fucking lash
		[ -f /usr/share/applications/lash-panel.desktop ] && sudo rm -f /usr/share/applications/lash-panel.desktop

		[ -f /usr/share/applications/nethack.desktop ] && sudo rm -f /usr/share/applications/nethack.desktop

		# change VirtualBox dir
		# comment it since we don't use virtualbox anymore
		#sed -i '/defaultMachine/s:defaultMachineFolder="[^"]*":defaultMachineFolder="'~/.vm\": ~/.config/VirtualBox/VirtualBox.xml
	fi

	# since debian default don't have selinux active
	[ "$distro" != debian ] && chcon -Rt httpd_sys_content_t ~/w
	sudo firewall-cmd --add-service http
	sudo firewall-cmd --add-service https
	sudo firewall-cmd --add-port 8080/tcp	# we use 8080 for znc
	sudo firewall-cmd --runtime-to-permanent

	crontab $scriptdir/../conf/$distro/cron
}

hardlinks(){
	# hard link conf/home/foo to ~/.foo
	pushd $scriptdir/../conf/home
	for i in $(find -type f);
	do
		ln -f $i ~/.${i#./} && say "${i#./} linked"
	done
	popd
}

rm_wine_icons(){
	# fucking wine-desktops
	[ -f /usr/share/applications/wine.desktop ] && { say "The damn wine icons show again, let's clease them"; sudo rm -f /usr/share/applications/wine*.desktop; }
}

sounds() {
	[ $distro == rhel ] && return
	cp -r $scriptdir/../sound ~/.local && say ".local/sound copied"
}

redb() {
	[ $distro == rhel ] && return
	# import mysql backups
	say import cm
	say import grind
}

say(){
	echo -e '\e[33;1m'$@'\e[m'
}

_mkswap(){
	local i
	echo don\'t forget to make a swap
}

############### Main Part ###############

case $1 in
	"-a")
		more_repo
		rmapps
		inapps
		addgrp
		mysqldir
		gset
		sethostname
		settimezone
		dir_struct
		default_pool
		getcomposer
		misc
		hardlinks
		mod_bashrc
		rm_wine_icons
		redb
		_mkswap
		;;
	-s)
		sudoer
		;;
	-d)
		more_repo
		;;
	"")
		dir_struct
		mod_bashrc
		hardlinks
		rm_wine_icons
		;;
	*)
		;;
esac
