#!/bin/bash

if [ ! $USER = 'root' ]; then
    echo "script must be run as root"
    exit
fi

# apt.brightbox.net is used to install package libapache2-mod-passenger
if [ -f /etc/apt/sources.list.d/brightbox.list ]; then
    echo "brightbox installed"
else
    echo "deb http://apt.brightbox.net hardy main" > /etc/apt/sources.list.d/brightbox.list

    if [ ! -f /etc/apt/sources.list.d/brightbox.list ]; then
	echo "failed to create /etc/apt/sources.list.d/brightbox.list"
	exit
    fi

    /usr/bin/wget -q -O - http://apt.brightbox.net/release.asc | /usr/bin/apt-key add -
fi

/usr/bin/apt-get update

if ! ( /usr/bin/dpkg -S openssh-server >& /dev/null ); then
    ANSWER=n
    echo "install package openssh-server (y/n):"
    read -e ANSWER
    if [ $ANSWER = 'y' ]; then
	/usr/bin/apt-get -y install openssh-server
    fi
fi

/usr/bin/apt-get -y install mysql-server mysql-client ruby1.8 ruby1.8-dev rdoc1.8 libmagick9-dev libimage-size-ruby1.8 g++ gcc libmysql-ruby1.8 irb openssl zip unzip libopenssl-ruby apache2 memcached libmysqlclient15-dev build-essential git-core rubygems rake libxslt1-dev libapache2-mod-passenger

if [ ! -f /usr/bin/gem ]; then
    echo "/usr/bin/gem not found. Can not install required gems."
    exit
fi

/usr/bin/gem install starling fastthread daemons

/etc/init.d/memcached restart

