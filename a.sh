##!/bin/bash
#
# A script for quickly implementing softwares and settings after a Linux fresh installation. Mainly for Fedora semiannual upgrade purpose re-installation.

############### Variables ###############
user=al
hostname=tes
errlog=ash_error.log

# dir where this script in, no symbol link, so we don't need absolute path. Just don't cd to somewhere else.
scriptdir=$(dirname $0)

if [ -f /etc/os-release ]; then
	. /etc/os-release
	distro=$ID
	distro_ver=$VERSION_ID
else
	# bsd
	distro=$(uname)
fi
case $distro in
	fedora)
		yum=dnf
		;;
	rhel)
		;&
	centos)
		yum=yum
		distro=rhel
		;;
	debian)
		yum=apt
		;;
	freebsd)
		:
		;;
esac

t=$(uname -r)
[ "${t##*Microsoft*}" ] || is_WSL=my_length_is_nonzero

############### Functions ###############

sudoer() {
	[ $UID -ne 0 ] && say "$0: Permission denied" && exit
	if ! id $user &> /dev/null ; then
		say user $user not exist, now creating...
		useradd -m $user -s /bin/bash	# debian need to specify shell
		#echo $user | sudo passwd --stdin $user # debian have no --stdin option
		echo $user:$user | sudo chpasswd
	fi

	$yum install -y sudo

	say making $user sudoer...
	if [ "$distro" = debian ]; then
		usermod -aG sudo $user
	else
		usermod -aG wheel $user
	fi
	cp $scriptdir/conf/templates/$distro/sudoer /etc/sudoers.d/
}

_init() {
	# TODO internet?
	#id $user &> /dev/null || { say user $user no exist, run $0 -s to create. ; exit; }
	[ "$UID" -eq 0 ] && say "DO NOT use root, assohole!" && exit

	say adding some repository...
	ilist="screen nginx vim openssh-server unzip curl wireguard-tools"
    # mdadm
	case $distro in
		fedora)
			sudo $yum install -y http://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm http://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm > /dev/null && say "rpmfusion repo installed" || say "rpmfusion repo install failed"
			# add chrome repo
			sudo cp $scriptdir/conf/templates/google-chrome.repo /etc/yum.repos.d/ && say "chrome repo installed" || say "chrome repo install failed"
			php_with_exts=$(echo php php-{common,cli,xml,gd,pdo,opcache,mbstring,mysqlnd,json,fpm,devel})
			ilist="rsync xorg-x11-server-Xorg xorg-x11-xinit ibus-libpinyin cronie pulseaudio alsa-utils bash-completion $ilist i3 xautolock lightdm-gtk lightdm feh httpd mod_ssl mariadb-server $php_with_exts git ImageMagick nodejs nasm nmap samba wireshark irssi jq cmus whois transmission-common transmission-daemon libvirt qemu-kvm oathtool google-chrome-stable firefox mpv unrar @Fonts"
			#xorg-x11-drv-nvidia compton gcl postfix aircrack-ng libpcap-devel pixiewps sway arandr tlp id3v2 jmtpfs dnsmap dnsenum arp-scan macchanger xdotool testdisk sysstat ffmpeg virt-manager autoconf automake dosemu obs-studio gimp blender dsniff ettercap driftnet reaver rdesktop chntpw qrencode zbar android-tools libnotify zenity wine-core wine-mono wine-common mingw64-wine-gecko mingw32-wine-gecko wine-dxvk
			rlist="@gnome-desktop @LibreOffice nano eog evince evince-nautilus evince-libs evince-djvu flatpak PackageKit-glib PackageKit-command-not-found tmux virtualbox-guest-additions simple-scan evolution-help evolution-ews evolution bijiben rhythmbox shotwell transmission-gtk orca empathy gedit devassistant-core vinagre totem-nautilus totem cheese file-roller baobab setroubleshoot yelp seahorse abrt jwhois esmtp"
			;;
		rhel)
			# The epel-release package is available from the CentOS Extras repository (enabled by default) and will be pulled in as a dependency of ius-release automatically
			sudo rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-$distro_ver.noarch.rpm
			sudo $yum install -y https://${distro}${distro_ver}.iuscommunity.org/ius-release.rpm

			#nic=$(nmcli d | grep ethernet | cut -d" " -f1)
			#sudo sed -i /ONBOOT/s/=.*/=yes/ /etc/sysconfig/network-scripts/ifcfg-$nic
			nmcli d connect $nic

			# TODO, version
			php=php72u
			php=$(echo $php $php-{common,cli,xml,gd,pdo,opcache,mbstring,mysqlnd,json,fpm,fpm-nginx} mod_$php)
			ilist="$ilist httpd24u httpd24u-mod_ssl $php mariadb101u-server git2u psmisc xz bzip2 bash-completion znc"
			rlist="mariadb-libs git"
			;;
		debian)
            # comment out default apt sources
            sudo sed -i 's/^/#/' /etc/apt/sources.list

			# add testing repo (latest packages)
			sudo cp $scriptdir/conf/templates/debian/sources_z.list /etc/apt/sources.list.d/

			sudo $yum update -y

			php_ver=$(apt list php -a | grep testing | cut -d':' -f2)
			php=php${php_ver%+*}
			php_with_exts=$(echo $php-{common,cli,xml,gd,opcache,mbstring,zip,mysql,curl,json,fpm,uploadprogress})
			ilist="$ilist apache2 $php_with_exts mariadb-server firewalld redis-server git python3-pip psmisc xz-utils bzip2 bash-completion man-db znc"
			# unixodbc unixodbc-dev selinux-basics selinux-policy-default auditd"
			# libapache2-mod-$php apache2-dev libssl-dev libxml2-dev libcurl3-dev libpng-dev pkg-config lsb-release
			# Run selinux-activate(as root) to configure GRUB and PAM and to create /.autorelabel
			;;
	esac
}

remove_pkg() {
	[ $distro = debian ] && return
	say removing unneeded packages...
	for i in $rlist
	do
		rpm -q $i &> /dev/null && { sudo $yum remove -y $i > /dev/null && say "$i removed" || say "$i remove failed"; }
	done

	sudo $yum autoremove -y
	#sudo $yum clean all # although debian don't have 'all'
}

install_pkg() {
	say updating...
	sudo $yum upgrade -y

	say installing packages...
	for i in $ilist
	do
		sudo $yum install -y $i > /dev/null && say "$i installed" || { echo "$i install failed" | tee -a $errlog; }
	done
}

getcomposer(){
	if [ ! -x ~/.local/bin/composer ];then
		say get composer...
		local a=composer-setup.php
		curl -L https://getcomposer.org/installer -o $a
		# TODO not return
		if echo -n $(curl -s https://composer.github.io/installer.sig) $a | sha384sum -c --status;then
			php $a && rm $a
			mkdir ~/.local/bin -p
			mv composer.phar ~/.local/bin/composer
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
		sudo usermod -a -G wireshark,libvirt $USER && say "added $USER to wireshark,libvirt"
}

mysqldir(){
	# move mysql dir to home on fedora
	[ $distro != fedora ] && return
	# generate /var/lib/mysql/mysql.sock
	sudo systemctl restart mariadb
	say changing mysql datadir...

	local prefix serverconf
	prefix=~/.mysql
	serverconf = /etc/my.cnf.d/mariadb-server.cnf

	mkdir -p $prefix
	chcon -t mysqld_db_t $prefix
	sudo chown mysql:mysql $prefix

	# copy this line
	sudo sed -i "/^datadir/p" $serverconf
	# prepend # to comment this line
	sudo sed -i "1,/^datadir/s/^datadir/#datadir/" $serverconf
	sudo sed -i "/^datadir=/s:/.*:${prefix}/main:" $serverconf
	sudo sed -i '/\[mysqld\]/a character-set-server = utf8mb4' $serverconf
	# we better use the defaut mysql.sock path
	# copy this line
	#sudo sed -i "/^socket/p" $serverconf
	# prepend # comment this line
	#sudo sed -i "1,/^socket/s/^socket/#socket/" $serverconf
	#sudo sed -i "/^socket=/s:/.*:${prefix}/mysql.sock:" $serverconf

	sudo -u mysql mysql_install_db

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
		git pull
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
	gsettings set $schema cursor-shape 'block'
	gsettings set $schema cursor-blink-mode 'off'

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
	mkdir -p ~/w
	rmdir ~/{Downloads,Documents,Pictures,Music,Videos,Desktop,Public,Templates} 2>/dev/null
}

default_pool(){
	[ "$distro" != fedora ] && return
	sudo systemctl restart libvirtd
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
		# get rid of bash.bashrc
		sudo mv /etc/bash.bashrc /etc/bash.bashrc.fuck

        # Use server priorities for cipher algorithm choice.
        sudo sed -i '/SSLHonorCipherOrder/s/#//' /etc/apache2/mods-enabled/ssl.conf

        # mod_http2 doesn't work with mpm_prefork'
        # and "event mpm is nowadays the best one"
        # https://httpd.apache.org/docs/2.4/howto/http2.html#mpm-config
        sudo a2dismod php* mpm_prefork # disable all version of mod_php or mpm_prefork won't be disabled due to dependency
        sudo a2enmod mpm_event http2 rewrite ssl socache_shmcb headers proxy_fcgi setenvif
        sudo a2enconf $php-fpm

		sudo ln -s ~/vhosts /etc/apache2/sites-enabled/
		sudo ln -s ~/vhosts.conf /etc/apache2/conf-enabled/

		# use mysql native password insead of system user credentials
		sudo mysql -e "use mysql; UPDATE user SET plugin='mysql_native_password' WHERE User='root'"
		sudo mysql -e "FLUSH PRIVILEGES"

		sudo systemctl stop nginx redis-server
		sudo systemctl disable nginx redis-server

		# debain default using dash, change to bash
		sudo ln -sf bash /bin/sh
	fi

	if [ "$distro" = fedora ]; then
		sudo firewall-cmd --add-service samba
		# sudo firewall-cmd --remove-service ssh
		sudo systemctl disable libvirtd cups.socket
		sudo systemctl mask bluetooth

		sudo ln -s ~/.vhosts /etc/httpd/conf.d/
		sudo ln -s ~/.vhosts.conf /etc/httpd/conf.d/
	fi

	# since debian default don't have selinux active
	[ "$distro" != debian ] && chcon -Rt httpd_sys_content_t ~/w
	sudo firewall-cmd --add-service http
	sudo firewall-cmd --add-service https
	sudo firewall-cmd --add-port 8080/tcp	# we use 8080 for znc
	sudo firewall-cmd --runtime-to-permanent

	crontab $scriptdir/conf/templates/$distro/cron
}

hardlinks(){
	# hard link conf/home/foo to ~/.foo
	pushd $scriptdir/conf/home

	for i in $(find . -type d)
	do
		mkdir -p ~/.${i#./}
	done

	for i in $(find . -type f)
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
	cp -r $scriptdir/sound ~/.local && say ".local/sound copied"
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
	local swapfile
	swapfile=/swapfile
	[ $distro != debian -o "$is_WSL" -o -f "$swapfile" ] && return
	# dd, fallocate, truncate
	# https://stackoverflow.com/questions/257844/quickly-create-a-large-file-on-a-linux-system
	# https://askubuntu.com/questions/1017309/fallocate-vs-dd-for-swapfile
	#dd if=/dev/zero of=$swapfile bs=1 count=0 seek=2G # pretty fast using seek, but have holes
    say Making swap file...
	sudo dd if=/dev/zero of=$swapfile bs=4M count=500
	sudo chmod 600 $swapfile
	sudo mkswap $swapfile
	sudo swapon $swapfile
    sudo sed -i '$a'"$swapfile none swap defaults 0 0" /etc/fstab
}

_sysctl(){
	local f;
	f=$scriptdir/conf/templates/$distro/z-sysctl.conf
	if [ -f $f ]; then
		sudo cp $scriptdir/conf/templates/$distro/z-sysctl.conf /etc/sysctl.d/
		sudo sysctl -p $f
	fi
}

setupwg(){
	:
}

############### Main ###############

case $1 in
	"-a")
		_mkswap
		_init
		remove_pkg
		install_pkg
		addgrp
		mysqldir
		sethostname
		settimezone
		dir_struct
		default_pool
		getcomposer
		misc
		hardlinks
		rm_wine_icons
		redb
		_sysctl
		setupwg
		;;
	-s)
		sudoer
		;;
	-d)
		default_pool
		;;
	-H)
		hardlinks
		;;
	-S)
		_sysctl
		;;
	-C)
		getcomposer
		;;
	-w)
		_mkswap
		;;
	"")
		;;
	*)
		;;
esac
