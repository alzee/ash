#!/bin/bash
#
# A script for quickly implementing softwares and settings after a Linux fresh installation.
# Mainly for Fedora semiannual upgrade purpose re-installation.

[ "$UID" -eq 0 ] && echo "Do NOT use root!" && exit
############### Variables ###############
user=al
hostname=ash
errlog=ash_error.log

# dir where this script in, no symbol link, so we don't need absolute path. Just don't cd to somewhere else.
scriptdir=$(dirname $0)
tempdir=$(mktemp -d XXXXX)

if [ -f /etc/os-release ]; then
    . /etc/os-release
    distro=$ID
    distro_ver=$VERSION_ID
fi

case $distro in
    fedora)
        pkg=dnf
        ;;
    rhel)
        ;&
    centos)
        pkg=yum
        distro=rhel
        ;;
    debian)
        pkg=apt
        ;;
    freebsd)
        pkg=pkg
        :
        ;;
esac

kernel=$(uname -r)
[ "${kernel##*Microsoft*}" ] || is_WSL=my_length_is_nonzero

############### Functions ###############
_clean(){
    popd 2> /dev/null
    rm -rf "$tempdir"
}
trap _clean EXIT

sudoer() {
    [ $UID -ne 0 ] && say "$0: Permission denied" && exit
    if ! id $user &> /dev/null ; then
        say user $user not exist, now creating...
        useradd -m $user -s /bin/bash	# debian need to specify shell
        #echo $user | sudo passwd --stdin $user # debian have no --stdin option
        echo $user:$user | sudo chpasswd
    fi

    $pkg install -y sudo

    say making $user sudoer...
    if [ "$distro" = debian ]; then
        usermod -aG sudo $user
    else
        usermod -aG wheel $user
    fi
    cp $scriptdir/conf/templates/$distro/sudoer /etc/sudoers.d/
}

add_repo() {
    say adding some repository...

    case $distro in
        fedora)
            sudo $pkg install -y\
                https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm\
                https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

            sudo $pkg config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
            sudo $pkg config-manager --add-repo $scriptdir/conf/templates/$distro/symfony-cli.repo
            # repo for docker-ce docker-ce-cli containerd.io. No need since fedora comes with moby-engine
            # sudo $pkg config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
            ;;
        rhel)
            # The epel-release package is available from the CentOS Extras repository (enabled by default)
            # and will be pulled in as a dependency of ius-release automatically
            sudo rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-$distro_ver.noarch.rpm
            sudo $pkg install -y https://${distro}${distro_ver}.iuscommunity.org/ius-release.rpm
            ;;
        debian)
            # comment out default apt sources
            sudo sed -i 's/^/#/' /etc/apt/sources.list
            # add testing repo (latest packages)
            sudo cp $scriptdir/conf/templates/debian/testing.list /etc/apt/sources.list.d/
            sudo $pkg update -y
            ;;
        freebsd)
            ;;
    esac

    say updating...
    # upgrade first to avoid bug like libc6
    # https://bugs.launchpad.net/ubuntu/+source/glibc/+bug/1866844
    sudo $pkg upgrade -y

}

load_pkg() {
    i_pkg="$(< $scriptdir/pkg/general) $(< $scriptdir/pkg/$distro/install_pkg)"
    r_pkg=$(< $scriptdir/pkg/$distro/remove_pkg)
    case $distro in
        fedora)
            php=php
            ;;
        rhel)
            php=php
            ;;
        debian)
            php_ver=$(apt list php -a | grep testing | cut -d':' -f2)
            php=php${php_ver%+*}
            ;;
        freebsd)
            php_ver=80
            php=php${php_ver}
            ;;
    esac

    # TODO This will substitute something like `pkg-php-tools'
    # An alternative is start pattern with a space ${i_pkg// php-/ $php-}
    # but seems separators in foo=$(< bar) are not space
    i_pkg=${i_pkg//php-/$php-}
}

active_selinux_on_debian(){
    # selinux-basics selinux-policy-default auditd"
    # Run selinux-activate(as root) to configure GRUB and PAM and to create /.autorelabel
    :
}

remove_pkg() {
    say removing unneeded packages...
    for i in $r_pkg
    do
        say "Removing $i"
        sudo $pkg remove -y $i
    done

    sudo $pkg autoremove -y
    #sudo $pkg clean all # although debian don't have 'all'
}

install_pkg() {
    say installing packages...
    for i in $i_pkg
    do
        sudo $pkg install -y $i > /dev/null && say "$i installed" || { echo "$i install failed" | tee -a $errlog; }
    done
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
    if [ $distro = fedora ]
        sudo usermod -a -G wireshark $USER && say "added $USER to wireshark"
        sudo usermod -a -G libvirt $USER && say "added $USER to libvirt"
        sudo usermod -a -G docker $USER && say "added $USER to docker"
    fi
}

mysqldir(){
    # move mysql dir to home on fedora
    [ $distro != fedora ] && return
    # generate /var/lib/mysql/mysql.sock
    sudo systemctl restart mariadb
    say changing mysql datadir...

    local prefix serverconf
    prefix=~/.mysql
    serverconf=/etc/my.cnf.d/mariadb-server.cnf

    mkdir -p $prefix
    sudo chcon -t mysqld_db_t $prefix
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

sethostname(){
    say changing hostname to $hostname
    sudo hostname $hostname
    sudo sed -i s/.*/$hostname/ /etc/hostname
    # sudo hostnamectl set-hostname $hostname

    # add hostname to /etc/hosts
    say add hostname to /etc/hosts
    if ! grep -wq `hostname` /etc/hosts; then
        sudo sed -i \$a"127.0.0.1 `hostname`" /etc/hosts
    fi
}

settimezone(){
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
        sudo mv /etc/bash.bashrc /etc/bash.bashrc.bak

        # mod_http2 doesn't work with mpm_prefork'
        # and "event mpm is nowadays the best one"
        # https://httpd.apache.org/docs/2.4/howto/http2.html#mpm-config
        # Disable all version of mod_php or mpm_prefork won't be disabled due to dependency
        sudo a2dismod php* mpm_prefork
        sudo a2enmod mpm_event http2 rewrite ssl socache_shmcb headers proxy_{fcgi,http,http2} setenvif
        sudo a2enconf $php-fpm

        #sudo ln -s ~/vhosts /etc/apache2/sites-enabled/
        sudo ln -s ~/vhosts.conf /etc/apache2/conf-enabled/

        # use mysql native password insead of system user credentials
        sudo mysql -e "use mysql; UPDATE user SET plugin='mysql_native_password' WHERE User='root'"
        # This way will disallow `sudo mysql'
        # sudo mysql -e "alter user root@localhost identified by 'toor'"
        # This way will allow `sudo mysql'
        sudo mysqladmin -u root password toor
        sudo mysql -e "FLUSH PRIVILEGES"

        sudo systemctl stop nginx redis-server
        sudo systemctl disable nginx redis-server

        # debain default using dash, change to bash
        sudo ln -sf bash /bin/sh
    fi

    if [ "$distro" = fedora ]; then
        sudo firewall-cmd --add-service http
        sudo firewall-cmd --add-service https
        sudo firewall-cmd --add-service samba
        sudo firewall-cmd --add-service http --zone libvirt
        sudo firewall-cmd --add-service https --zone libvirt
        sudo firewall-cmd --add-service samba --zone libvirt
        # sudo firewall-cmd --remove-service ssh
        sudo firewall-cmd --runtime-to-permanent
        sudo systemctl disable libvirtd cups.socket
        sudo systemctl mask bluetooth

        # start docker to initialize /etc/docker/
        sudo systemctl start docker
        sudo cp $scriptdir/conf/daemon.json /etc/docker/

        #sudo ln -s ~/.vhosts /etc/httpd/conf.d/
        sudo ln -s ~/.vhosts.conf /etc/httpd/conf.d/vhosts.conf

        sudo setsebool -P httpd_can_network_connect 1   # so php-fpm can access mysql port
        sudo setsebool -P samba_enable_home_dirs 1

        sudo chcon -Rt httpd_sys_content_t ~/w

        # run tcpdump as non-root, seems no need to add user to group
        # https://askubuntu.com/a/632189
        sudo setcap cap_net_raw,cap_net_admin=eip /sbin/tcpdump
    fi

    crontab $scriptdir/conf/templates/$distro/cron
    
    # https://forums.developer.nvidia.com/t/no-matching-gpu-found-with-510-47-03/202315/5
    # nvidia-powerd is only for mobile gpus
    # $pkg remove -y xorg-x11-drv-nvidia-power
}

setup_auto_upgrade(){
    if [ "$distro" = debian ]; then
        sudo $pkg install -y unattended-upgrades # In case not installed yet.
        local file=/etc/apt/apt.conf.d/50unattended-upgrades
        # Uncomment these lines in /etc/apt/apt.conf.d/50unattended-upgrades
        a='origin=Debian,codename=${distro_codename}-updates'
        b='origin=Debian,codename=${distro_codename}-proposed-updates'
        c='Unattended-Upgrade::Mail '
        d='Unattended-Upgrade::Remove-Unused-Dependencies'

        sudo sed -i "/$a\|$b\|$c\|$d/s://::" $file
        sudo sed -i "/$c/s:\"\":\"$user\":" $file
        sudo sed -i "/$d/s:false:true:" $file

        # Generate /etc/apt/apt.conf.d/20auto-upgrades
        sudo dpkg-reconfigure -plow unattended-upgrades
    fi

    if [ "$distro" = fedora ]; then
        sudo $pkg install -y dnf-automatic   # In case not installed yet.
        local file=/etc/dnf/automatic.conf
        sudo sed -i '/apply_updates/s/no/yes/' $file
        sudo systemctl enable --now dnf-automatic.timer postfix
    fi
}

_hardlinks(){
    local dotfiles
    # hard link ~/.foo to conf/home/foo
    pushd ~

    for i in $(find $dotfiles -type d)
    do
        mkdir -p $scriptdir/conf/home/${i#./.}
    done

    for i in $(find $dotfiles -type f)
    do
        ln -f $i $scriptdir/confi/home/${i#./.} && say "${i#./.} linked"
    done

    popd
}

hardlinks(){
    # hard link conf/home/foo to ~/.foo
    pushd $scriptdir/conf/home

    for i in $(find . -type d)
    do
        mkdir -p ~/.${i#./}
    done

    for i in $(find . -xtype f)
    do
        ln -f $i ~/.${i#./} && say "${i#./} linked"
    done

    popd
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

setup_wg(){
    :
}

install_composer(){
    if [ ! -x ~/.local/bin/composer ];then
        say Installing composer...
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

install_node(){
    node_tar='node-lts-linux.x64.tar.xz'
    node_url=$(curl -s https://nodejs.org/en/download/ | grep -o 'https://.*linux-x64.tar.xz')
    pushd $tempdir
    curl -o $node_tar $node_url
    tar xf $node_tar
    cp -a node-*/{bin/,include/,lib/,share/} ~/.local/
    popd
    PATH=$PATH:$HOME/.local/bin
    N_PREFIX=~/.local npm -g install n
    if [ "$distro" = fedora ]; then
        npm -g install sass @angular/cli @ionic/cli
        # npm -g install cordova cordova-res
    fi
}

############### Main ###############

case $1 in
    -a)
        _mkswap
        add_repo
        load_pkg
        install_pkg
        remove_pkg
        setup_auto_upgrade
        sethostname
        addgrp
        mysqldir
        settimezone
        dir_struct
        default_pool
        misc
        install_composer
        install_node
        hardlinks
        _sysctl
        setup_wg
        ;;
    -s)
        sudoer
        ;;
    -C)
        install_composer
        ;;
    -N)
        install_node
        ;;
    -D)
        default_pool
        ;;
    -H)
        hardlinks
        ;;
    -Y)
        _sysctl
        ;;
    -w)
        _mkswap
        ;;
    -r)
        add_repo
        ;;
    -U)
        setup_auto_upgrade
        ;;
    *)
        ;;
esac
