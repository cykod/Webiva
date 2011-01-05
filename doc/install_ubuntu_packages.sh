#!/bin/bash

if [ ! $USER = 'root' ]; then
    echo "script must be run as root"
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

/usr/bin/apt-get update
/usr/bin/apt-get -y install mysql-server mysql-client ruby1.8 ruby1.8-dev rdoc1.8 libmagick9-dev libimage-size-ruby1.8 g++ gcc libmysql-ruby1.8 irb openssl zip unzip libopenssl-ruby apache2 memcached libmysqlclient15-dev build-essential git-core rubygems rake libxslt1-dev libapache2-mod-passenger

if ! ( /usr/bin/dpkg -l | grep openssh-server >& /dev/null ); then
    ANSWER=n
    echo "Install openssh-server (y/n):"
    read -e ANSWER
    if [ $ANSWER = 'y' ]; then
	/usr/bin/apt-get -y install openssh-server
    fi
fi

if [ ! -f /usr/bin/gem ]; then
    echo "/usr/bin/gem not found. Can not install required gems."
    exit
fi

/usr/bin/gem install starling fastthread daemons httparty fastercsv resthome --no-rdoc --no-ri

echo "# Set this to yes to enable memcached.
ENABLE_MEMCACHED=yes" > /etc/default/memcached

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

if [ ! -f /var/run/mysqld/mysqld.pid -a ! -S /var/run/mysqld/mysqld.sock ]; then
    echo "Halting, MySQL is not running"
    exit
fi

if [ ! -f /var/run/memcached.pid ]; then
    echo "Halting, memcached is not running"
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
