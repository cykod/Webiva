#!/bin/bash

if [ ! $USER = 'root' ]; then
    echo "script must be run as root"
    exit
fi

if [ ! -f /etc/apt/sources.list ]; then
    echo "/etc/apt/sources.list not found. Can not continue."
    exit
fi

#configuration options for your environment

DEV_USER=notroot
DOMAIN=mywebiva.com
WEBIVA_BASE_DIR=/home/$DEV_USER
WEBIVA_DIR=$WEBIVA_BASE_DIR/Webiva
RAILS_ENV=development

if ( ! grep $DEV_USER /etc/passwd >& /dev/null ); then
    echo "$DEV_USER was not found in /etc/passwd"
    echo "update the DEV_USER variable above with the correct user"
    exit
fi

# uncomment if you haven't setup standard lenny source
#if ( /bin/grep ftp.us.debian.org /etc/apt/sources.list >& /dev/null || /bin/grep http.us.debian.org /etc/apt/sources.list >& /dev/null ); then
#    echo "http.us.debian.org installed"
#else
#    echo "deb http://ftp.us.debian.org/debian/ lenny main contrib non-free
#deb-src http://ftp.us.debian.org/debian/ lenny main contrib non-free" >> /etc/apt/sources.list
#fi

# package required by Webiva
if ! ( /usr/bin/dpkg -S mysql-server mysql-client ruby1.8 ruby1.8-dev rdoc1.8 libmagick9-dev libimage-size-ruby1.8 g++ gcc libmysql-ruby1.8 irb openssl zip unzip libopenssl-ruby apache2 memcached libmysqlclient15-dev build-essential git-core rubygems rake libxslt1-dev >& /dev/null ); then
    /usr/bin/apt-get update
    /usr/bin/apt-get -y install mysql-server mysql-client ruby1.8 ruby1.8-dev rdoc1.8 libmagick9-dev libimage-size-ruby1.8 g++ gcc libmysql-ruby1.8 irb openssl zip unzip libopenssl-ruby apache2 memcached libmysqlclient15-dev build-essential git-core rubygems rake libxslt1-dev
fi

if ! ( /usr/bin/dpkg -S mysql-server mysql-client ruby1.8 ruby1.8-dev rdoc1.8 libmagick9-dev libimage-size-ruby1.8 g++ gcc libmysql-ruby1.8 irb openssl zip unzip libopenssl-ruby apache2 memcached libmysqlclient15-dev build-essential git-core rubygems rake libxslt1-dev >& /dev/null ); then
    echo "Halting, required packages not found."
    exit
fi

if ! ( /usr/bin/dpkg -S openssh-server >& /dev/null ); then
    ANSWER=n
    read -p "Install openssh-server (y/n): " ANSWER
    if [ $ANSWER = 'y' ]; then
	apt-get -y install openssh-server
    fi
fi

# www.backports.org is used to install librack-ruby1.8
if ( ! /usr/bin/dpkg -S librack-ruby1.8 >& /dev/null ); then
    ADDED_BACKPORTS=0

    if ( /bin/grep lenny-backports /etc/apt/sources.list >& /dev/null || /bin/ls /etc/apt/sources.list.d/backports.list >& /dev/null ); then
	echo "lenny-backports installed"
    else
	ANSWER=n
	echo "lenny-backports is required to install librack-ruby1.8"
	read -p "Do you want to install lenny-backports? (y/n): " ANSWER
	if [ $ANSWER = 'y' ]; then
	    ADDED_BACKPORTS=1
	    echo "deb http://www.backports.org/debian lenny-backports main contrib non-free" > /etc/apt/sources.list.d/backports.list
	    wget -q -O - http://www.backports.org/debian/archive.key | apt-key add -
	    /usr/bin/apt-get update
	else
	    echo "Halting, librack-ruby1.8 required."
	    exit
	fi
    fi

    if ! ( /usr/bin/apt-get -y install -t lenny-backports librack-ruby1.8 >& /dev/null ); then
	echo "failed to install librack-ruby1.8 from lenny-backports"
	exit
    fi

    echo ""
    echo "librack-ruby1.8 is installed"
    echo ""

    if [ $ADDED_BACKPORTS = 1 ]; then
	ANSWER=n
	read -p "Do you want to uninstall lenny-backports (y/n): " ANSWER
	if [ $ANSWER = 'y' ]; then
	    /bin/mv /etc/apt/sources.list.d/backports.list /etc/apt/sources.list.d/backports.list.off
	    echo "Moved /etc/apt/sources.list.d/backports.list to /etc/apt/sources.list.d/backports.list.off"
	fi
    fi
fi

# debian.tryphon.org is used to install package libapache2-mod-passenger
if ( ! /usr/bin/dpkg -S libapache2-mod-passenger >& /dev/null ); then
    ADDED_TRYPHON=0

    if [ -f /etc/apt/sources.list.d/tryphon.list ]; then
	echo "tryphon installed"
    else
	ADDED_TRYPHON=1

	echo "deb http://debian.tryphon.org stable main contrib
deb-src http://debian.tryphon.org stable main contrib" > /etc/apt/sources.list.d/tryphon.list
	wget -q -O - http://debian.tryphon.org/release.asc | apt-key add -
	/usr/bin/apt-get update
    fi

    if ! ( /usr/bin/apt-get -y install libapache2-mod-passenger >& /dev/null ); then
	echo "failed to install libapache2-mod-passenger"
	exit
    fi

    echo ""
    echo "libapache2-mod-passenger is installed"
    echo ""

    if [ $ADDED_TRYPHON = 1 ]; then
	ANSWER=n
	read -p "Do you want to uninstall tryphon sources (y/n): " ANSWER
	if [ $ANSWER = 'y' ]; then
	    /bin/mv /etc/apt/sources.list.d/tryphon.list /etc/apt/sources.list.d/tryphon.list.off
	    echo "Moved /etc/apt/sources.list.d/tryphon.list to /etc/apt/sources.list.d/tryphon.list.off"
	fi
    fi
fi

if [ ! -f /usr/bin/gem ]; then
    echo "/usr/bin/gem not found. Can not install required gems."
    exit
fi

/usr/bin/gem install starling fastthread daemons httparty fastercsv resthome --no-rdoc --no-ri

/etc/init.d/memcached start

if [ ! -f /etc/apache2/sites-available/webiva ]; then
    echo "
<VirtualHost *:80>
   ServerName $DOMAIN
   ServerAlias www.$DOMAIN
   DocumentRoot $WEBIVA_DIR/public

   # Optional - set site to run as a specific user
   PassengerDefaultUser $DEV_USER

   # Optional - set to production or development as necessary
   RailsEnv $RAILS_ENV


   # We don't want any user uploaded scripts to be executed in the public directory
   # This should be the public/system directory of your webiva install
   <Directory "$WEBIVA_DIR/public/system">
         Options FollowSymLinks
         AllowOverride Limit
         Order allow,deny
         Allow from all
         <IfModule mod_php5.c>
          php_admin_flag engine off
        </IfModule>
        AddType text/plain .html .htm .shtml .php .php3 .phtml .phtm .pl
   </Directory>
</VirtualHost>
" > /etc/apache2/sites-available/webiva
fi

if [ ! -f /var/run/mysqld/mysqld.pid ]; then
    echo "Halting, MySQL is not running"
    exit
fi

if [ ! -f /usr/bin/sudo ]; then
    ANSWER=n
    echo "sudo is not installed"
    read -p "Do you want to install sudo? (y/n): " ANSWER
    if [ $ANSWER = 'y' ]; then
	/usr/bin/apt-get -y install sudo
    else
	echo "Halting, sudo is required for the rest of the setup"
	exit
    fi
fi

cd $WEBIVA_BASE_DIR

if [ ! -f $WEBIVA_DIR ]; then
    sudo -u $DEV_USER git clone git://github.com/cykod/Webiva.git

    cd $WEBIVA_DIR

    ANSWER=n
    echo ""
    read -p "Do you want to use the Webiva development branch? (y/n): " ANSWER
    if [ $ANSWER = 'y' ]; then
	sudo -u $DEV_USER git checkout --track -b development origin/development
    fi
fi

cd $WEBIVA_DIR

sudo -u $DEV_USER script/quick_install.rb

if [ -f /etc/apache2/sites-enabled/000-default ]; then
    ANSWER=n
    echo "Apache is setup with the default site."
    read -p "Do you want to disable default site? (y/n): " ANSWER
    if [ $ANSWER = 'y' ]; then
	/usr/sbin/a2dissite default
    fi
fi

if [ ! -f /etc/apache2/sites-enabled/webiva ]; then
    /usr/sbin/a2ensite webiva
fi

/etc/init.d/apache2 restart

cd $WEBIVA_DIR

sudo -u $DEV_USER RAILS_ENV=$RAILS_ENV PATH=$PATH:/var/lib/gems/1.8/bin script/background.rb start

if [ $RAILS_ENV = 'development' ]; then
    IP=`ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}' | head -1`
    echo ""
    echo "Add the following to your local /etc/hosts file."
    echo "$IP   $DOMAIN www.$DOMAIN"
    echo ""
    echo "Then goto http://www.$DOMAIN/website"
fi
