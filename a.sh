#!/bin/bash
#
# A script for quickly implementing softwares and settings after a Linux fresh installation.
# Mainly for Fedora semiannual upgrade purpose re-installation.

[ "$UID" -eq 0 ] && echo "Do NOT use root!" && exit
############### Variables ###############
user=$(whoami)
hostname=ash
errlog=ash_error.log

# dir where this script in, no symbol link, so we don't need absolute path. Just don't cd to somewhere else.
scriptdir=$(dirname $0)

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
[[ "$kernel" =~ [Mm]icrosoft ]] && is_WSL=my_length_is_nonzero

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

            sudo $pkg config-manager addrepo --from-repofile=https://cli.github.com/packages/rpm/gh-cli.repo
            # fedora have moby-engine. Anyway, use docker repo can get docker-compose-plugin
            sudo $pkg config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
            curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.rpm.sh | sudo bash
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
            # curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash
            # github cli
            # curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
            #     && sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
            #     && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            # # docker
            # see https://docs.docker.com/engine/install/debian/#install-using-the-repository
            curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
                https://download.docker.com/linux/debian \
                $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

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
    i_pkg="$(< $scriptdir/pkg/generic) $(< $scriptdir/pkg/$distro/install)"
    r_pkg=$(< $scriptdir/pkg/$distro/remove)
    case $distro in
        fedora)
            ;;
        rhel)
            ;;
        debian)
            ;;
        freebsd)
            ;;
    esac

    if [ "$IS_WORKSTATION" -a  -f $scriptdir/pkg/$distro/workstation ]; then
        i_pkg="$i_pkg $(< $scriptdir/pkg/$distro/workstation)"
    fi
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
    if [ $distro = fedora ]; then
        sudo usermod -a -G wireshark $USER && say "added $USER to wireshark"
        sudo usermod -a -G libvirt $USER && say "added $USER to libvirt"
        sudo usermod -a -G docker $USER && say "added $USER to docker"
    fi
}

mysqldir(){
    local prefix serverconf

    # generate /var/lib/mysql/mysql.sock
    sudo systemctl restart mariadb
    say changing mysql datadir...

    # move mysql dir to home on fedora
    prefix=~/.mysql

    mkdir -p $prefix
    sudo chown mysql:mysql $prefix

    if [ $distro = fedora ]; then
        serverconf=/etc/my.cnf.d/mariadb-server.cnf
        sudo chcon -R -t mysqld_db_t $prefix
    fi

    if [ $distro = debian ]; then
        serverconf=/etc/mysql/mariadb.conf.d/50-server.cnf

        # sudo systemctl edit mariadb.service
        # [Service]
        # ProtectHome=false
        local overridedir=/etc/systemd/system/mariadb.service.d
        sudo mkdir $overridedir
        echo -e '[Service]\nProtectHome=false' | sudo tee $overridedir/override.conf # > /dev/null
    fi

    # copy this line
    sudo sed -i "/^datadir/p" $serverconf
    # prepend # to comment this line
    sudo sed -i "1,/^datadir/s/^datadir/#datadir/" $serverconf
    sudo sed -i "/^datadir=/s:/.*:${prefix}/main:" $serverconf
    # sudo sed -i '/\[mysqld\]/a character-set-server = utf8mb4' $serverconf
    # we better use the defaut mysql.sock path
    # copy this line
    #sudo sed -i "/^socket/p" $serverconf
    # prepend # comment this line
    #sudo sed -i "1,/^socket/s/^socket/#socket/" $serverconf
    #sudo sed -i "/^socket=/s:/.*:${prefix}/mysql.sock:" $serverconf

    sudo -u mysql mariadb-install-db
    
    sudo systemctl restart mariadb
    #mariadb-secure-installation
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
    virsh pool-start default
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
        local php
        php=$(apt info php | grep Depends | cut -d' ' -f2)
        sudo a2enconf $php-fpm

        # Set apache default charset
        sudo sed -i '/#AddDefaultCharset/s/#//' /etc/apache2/conf-available/charset.conf

        #sudo ln -s ~/vhosts /etc/apache2/sites-enabled/
        sudo ln -s ~/vhosts.conf /etc/apache2/conf-enabled/

        sudo systemctl disable --now nginx redis-server nfs-server rpcbind #transmission-daemon

        # debain default using dash, change to bash
        sudo ln -sf bash /bin/sh
    fi

    if [ "$distro" = fedora ]; then
        sudo firewall-cmd --add-service http
        sudo firewall-cmd --add-service https
        sudo firewall-cmd --add-service samba
        sudo firewall-cmd --add-service vnc-server
        sudo firewall-cmd --add-service nfs
        sudo firewall-cmd --add-service http --zone libvirt
        sudo firewall-cmd --add-service https --zone libvirt
        sudo firewall-cmd --add-service samba --zone libvirt
        sudo firewall-cmd --runtime-to-permanent
        sudo systemctl disable libvirtd
        sudo systemctl enable --now sshd

        # start docker to initialize /etc/docker/
        sudo systemctl start docker
        sudo cp $scriptdir/conf/templates/daemon.json /etc/docker/

        #sudo ln -s ~/.vhosts /etc/httpd/conf.d/
        sudo ln -s ~/.vhosts.conf /etc/httpd/conf.d/vhosts.conf

        sudo setsebool -P httpd_can_network_connect 1   # so php-fpm can access mysql port
        sudo setsebool -P samba_enable_home_dirs 1

        sudo chcon -Rt httpd_sys_content_t ~/w

        # run tcpdump as non-root, seems no need to add user to group
        # https://askubuntu.com/a/632189
        sudo setcap cap_net_raw,cap_net_admin=eip /sbin/tcpdump

        # In case postfix warning: unable to look up public/pickup: No such file or directory
        sudo mkfifo /var/spool/postfix/public/pickup 2> /dev/null

        # If nvidia on desktop
        # sudo systemctl disable --now nvidia-powerd.service
    fi

    crontab $scriptdir/conf/templates/$distro/cron
    
    # https://forums.developer.nvidia.com/t/no-matching-gpu-found-with-510-47-03/202315/5
    # nvidia-powerd is only for mobile gpus
    # $pkg remove -y xorg-x11-drv-nvidia-power
}

setup_auto_upgrade(){
    local file o m d r
    if [ "$distro" = debian ]; then
        sudo $pkg install -y unattended-upgrades # In case not installed yet.
        file=/etc/apt/apt.conf.d/50unattended-upgrades
        # ${distro_codename}-updates & ${distro_codename}-proposed-updates
        o='origin=Debian,codename=${distro_codename}.*-updates'
        m='Unattended-Upgrade::Mail '
        d='Unattended-Upgrade::Remove-Unused-Dependencies'
        # Automatic-Reboot & Automatic-Reboot-WithUsers
        r='Unattended-Upgrade::Automatic-Reboot.*"\(false\|true\)"'

        # Set mail to
        sudo sed -i "/$m/s:\"\":\"$user\":" $file
        # Set Remove-Unused-Dependencies, Automatic-Reboot and Automatic-Reboot-WithUsers to true
        sudo sed -i "/$d\|$r/s:false:true:" $file
        # Uncomment these lines
        sudo sed -i "/$o\|$m\|$d\|$r/s://::" $file

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

mklinks(){
    # hard link conf/home/foo to ~/.foo
    for i in $(find $scriptdir/conf/home/ -type d)
    do
        mkdir -p ~/.${i#*home/}
    done

    for i in $(find $scriptdir/conf/home -xtype f)
    do
        if [ "$ANDROID_ROOT" ]; then
            # Create symbolics instead if on a android device
            ln -sf $PWD/$i ~/.${i#*home/} && say "${i#./} linked"
        else
            ln -f $i ~/.${i#*home/} && say "${i#./} linked"
        fi
    done
}

say(){
    echo -e '\e[33;1m'$@'\e[m'
}

_mkswap(){
    local swapfile
    swapfile=/mnt/swapfile
    [ $distro != debian -o "$is_WSL" -o -f "$swapfile" ] && return
    # dd, fallocate, truncate
    # https://stackoverflow.com/questions/257844/quickly-create-a-large-file-on-a-linux-system
    # https://askubuntu.com/questions/1017309/fallocate-vs-dd-for-swapfile
    # sudo fallocate --length 3700MiB  $swapfile
    #dd if=/dev/zero of=$swapfile bs=1 count=0 seek=2G # pretty fast using seek, but have holes
    say Making swap file...
    sudo dd if=/dev/zero of=$swapfile bs=1M count=3700
    sudo chmod 600 $swapfile
    sudo mkswap $swapfile
    sudo swapon $swapfile
    sudo sed -i '$a'"$swapfile none swap defaults 0 0" /etc/fstab
}

_sysctl(){
    local f
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

install_symfony(){
    if [ "$distro" = fedora ]; then
        curl -sS https://get.symfony.com/cli/installer | bash
        ln -s ../../.symfony5/bin/symfony .local/bin/
    fi
}

install_deno(){
    curl -fsSL https://deno.land/install.sh | sh
    mv ~/.deno/bin/deno ~/.local/bin/
}

install_rust(){
    curl --proto '=https' --tlsv1.3 https://sh.rustup.rs -sSf | sh
    echo Generating tab-completion scripts for your shell.
    mkdir -p ~/.local/share/bash-completion/completions/
    rustup completions bash >> ~/.local/share/bash-completion/completions/rustup
    rustup completions bash cargo >> ~/.local/share/bash-completion/completions/cargo
    rustup component add rust-analyzer
}

enable_networkmanager(){
    # Since we remove dhcpcd5
    # sudo echo denyinterfaces wlan0 >> /etc/dhcpcd.conf
    sudo sed -i /managed/s/false/true/ /etc/NetworkManager/NetworkManager.conf
}

setup_x11vnc(){
    if [ "$IS_WORKSTATION" ]; then
        cp $scriptdir/conf/templates/x11vnc.service /etc/systemd/system/
        # vncpasswd
        mkdir ~/.vnc
        echo 111 | vncpasswd -f > ~/.vnc/passwd
        # sudo systemctl enable --now x11vnc
    fi
}

vim_gnupg(){
    git clone https://github.com/jamessan/vim-gnupg ~/w/vim-gnupg
    mkdir -p ~/.vim/pack/gnupg/start/
    ln -s ~/w/vim-gnupg ~/.vim/pack/gnupg/start/
}

xorg_conf(){
    sudo cp -a $scriptdir/conf/templates/xorg.conf.d/ /etc/X11/
}

install_zed(){
    curl -f https://zed.dev/install.sh | sh
}

install_uv(){
    curl -LsSf https://astral.sh/uv/install.sh | sh
}

install_nvm(){
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    nvm install node
    nvm alias default node
}

install_fnm(){
    curl -fsSL https://fnm.vercel.app/install | bash
    . ~/.bashrc
    fnm i --latest
    #corepack enable yarn
    #corepack enable pnpm

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
        # mysqldir
        settimezone
        dir_struct
        default_pool
        misc
        install_composer
        install_symfony
        install_uv
        install_fnm
        mklinks
        _sysctl
        setup_wg
        ;;
    -s)
        sudoer
        ;;
    -m)
        mysqldir
        ;;
    -M)
        misc
        ;;
    -C)
        install_composer
        ;;
    -nvm)
        install_nvm
        ;;
    -R)
        install_rust
        ;;
    -d)
        install_deno
        ;;
    -D)
        default_pool
        ;;
    -L)
        mklinks
        ;;
    -y)
        install_symfony
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
    -V)
        setup_x11vnc
        ;;
    -v)
        vim_gnupg
        ;;
    -zed)
        install_zed
        ;;
    -uv)
        install_uv
        ;;
    -fnm)
        install_fnm
        ;;
    *)
        ;;
esac
