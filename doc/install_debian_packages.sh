#!/bin/bash

if [ ! $USER = 'root' ]; then
    echo "script must be run as root"
    exit
fi

if [ ! -f /etc/apt/sources.list ]; then
    echo "/etc/apt/sources.list not found. Can not continue."
    exit
fi

UPDATE=0

if ( /bin/grep ftp.us.debian.org /etc/apt/sources.list >& /dev/null || /bin/grep http.us.debian.org /etc/apt/sources.list >& /dev/null ); then
    echo "http.us.debian.org installed"
else
    UPDATE=1
    echo "deb http://ftp.us.debian.org/debian/ lenny main contrib non-free
deb-src http://ftp.us.debian.org/debian/ lenny main contrib non-free" >> /etc/apt/sources.list
fi

# www.backports.org is used to install librack-ruby1.8
if ( /bin/grep lenny-backports /etc/apt/sources.list >& /dev/null ); then
    echo "lenny-backports installed"
else
    UPDATE=1
    echo "deb http://www.backports.org/debian lenny-backports main contrib non-free" >> /etc/apt/sources.list
fi

# debian.tryphon.org is used to install package libapache2-mod-passenger
if [ -f /etc/apt/sources.list.d/tryphon.list ]; then
    echo "tryphon installed"
else
    UPDATE=1
    echo "deb http://debian.tryphon.org stable main contrib
deb-src http://debian.tryphon.org stable main contrib" > /etc/apt/sources.list.d/tryphon.list

    if [ ! -f /etc/apt/sources.list.d/tryphon.list ]; then
	echo "failed to create /etc/apt/sources.list.d/tryphon.list"
	exit
    fi
fi

if [ $UPDATE = 1 ]; then
    echo "running apt-get update"
    apt-get update
fi

if ! ( /usr/bin/dpkg -S openssh-server >& /dev/null ); then
    ANSWER=n
    echo "install package openssh-server (y/n):"
    read -e ANSWER
    if [ $ANSWER = 'y' ]; then
	apt-get -y install openssh-server
    fi
fi

if ! ( /usr/bin/apt-get -y install -t lenny-backports librack-ruby1.8 >& /dev/null ); then
    echo "failed to install librack-ruby1.8 from lenny-backports"
    exit
fi

/usr/bin/apt-get -y install mysql-server mysql-client ruby1.8 ruby1.8-dev rdoc1.8 libmagick9-dev libimage-size-ruby1.8 g++ gcc libmysql-ruby1.8 irb openssl zip unzip libopenssl-ruby apache2 memcached libmysqlclient15-dev build-essential git-core rubygems rake libxslt1-dev libapache2-mod-passenger

if [ ! -f /usr/bin/gem ]; then
    echo "/usr/bin/gem not found. Can not install required gems."
    exit
fi

/usr/bin/gem install starling fastthread daemons

/etc/init.d/memcached restart

