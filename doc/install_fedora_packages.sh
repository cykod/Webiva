#!/bin/bash

if [ ! $USER = 'root' ]; then
    echo "script must be run as root"
    exit
fi

#configuration options for your environment

DEV_USER=notroot
DOMAIN=mywebiva.com
PASSENGER_TMP_DIR=/var/www/tmp
WEBIVA_BASE_DIR=/var/opt/$DEV_USER
WEBIVA_DIR=/var/opt/$DEV_USER/Webiva
RAILS_ENV=development

if ( ! grep $DEV_USER /etc/passwd >& /dev/null ); then
    echo "$DEV_USER was not found in /etc/passwd"
    echo "update the DEV_USER variable above with the correct user"
    exit
fi

yum -y install mysql-server mysql rubygem-rails ruby-mysql ruby-rdoc ruby-devel ruby-imagesize rubygem-tlsmail libxslt libxslt-devel gcc ImageMagick-devel gcc-c++ apr-devel httpd-devel git mysql-devel memcached

gem install passenger starling fastthread daemons httparty fastercsv resthome --no-rdoc --no-ri

passenger-install-apache2-module

cd /usr/local/lib
ln -s /usr/lib64/mysql

mkdir $PASSENGER_TMP_DIR
chmod 777 $PASSENGER_TMP_DIR

mkdir $WEBIVA_BASE_DIR
chown $DEV_USER:$DEV_USER $WEBIVA_BASE_DIR
chmod 711 $WEBIVA_BASE_DIR

PASSENGER_CONFIG_DIR=`passenger-config --root`

# Apache Configs

# setup passenger
echo "LoadModule passenger_module $PASSENGER_CONFIG_DIR/ext/apache2/mod_passenger.so
PassengerRoot $PASSENGER_CONFIG_DIR
PassengerRuby /usr/bin/ruby
PassengerTempDir $PASSENGER_TMP_DIR" > /etc/httpd/conf.d/mod_passenger.conf

# setup Webiva

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
" > /etc/httpd/conf.d/webiva.conf

mv /etc/httpd/conf.d/welcome.conf /etc/httpd/conf.d/welcome.conf.off

# for SeLinux

if ( selinuxenabled ); then
    ANSWER=n
    echo ""
    echo ""
    echo "Setup SeLinux for Webiva (y/n):"
    read -e ANSWER
    if [ $ANSWER = 'y' ]; then
	chcon -R -h -t httpd_sys_content_t $PASSENGER_CONFIG_DIR
	chcon -R -h -t httpd_sys_content_rw_t $PASSENGER_TMP_DIR

	cd /etc/selinux

	echo "
module local 1.0;

require {
        type user_devpts_t;
        type user_home_dir_t;
        type user_home_t;
        type unconfined_t;
        type httpd_tmp_t;
        type httpd_sys_script_t;
        type memcache_port_t;
        type root_t;
        type port_t;
        type httpd_sys_content_rw_t;
        type public_content_rw_t;
        type var_t;
        type http_port_t;
        type httpd_t;
        class process getsched;
        class unix_stream_socket { read write shutdown };
        class chr_file { read write ioctl };
        class capability { setuid dac_read_search chown fsetid setgid fowner dac_override };
        class tcp_socket name_connect;
        class fifo_file { getattr setattr read create unlink };
        class sock_file { write create unlink getattr setattr };
        class dir { write search read create open getattr add_name };
        class file { write read create open getattr setattr };
}

#============= httpd_sys_script_t ==============
allow httpd_sys_script_t http_port_t:tcp_socket name_connect;
allow httpd_sys_script_t memcache_port_t:tcp_socket name_connect;
allow httpd_sys_script_t port_t:tcp_socket name_connect;
allow httpd_sys_script_t root_t:dir { write create add_name };
allow httpd_sys_script_t self:capability { setuid dac_read_search chown fsetid setgid fowner dac_override };
allow httpd_sys_script_t self:process getsched;
allow httpd_sys_script_t var_t:file { write read create open getattr setattr };
allow httpd_sys_script_t user_devpts_t:chr_file { read write ioctl };
allow httpd_sys_script_t user_home_dir_t:dir { write search read create open getattr add_name };
allow httpd_sys_script_t user_home_t:dir { write search read create open getattr add_name };

#============= httpd_t ==============
allow httpd_t httpd_sys_script_t:unix_stream_socket { read write shutdown };
allow httpd_t httpd_sys_content_rw_t:fifo_file { getattr setattr read create unlink };
allow httpd_t httpd_sys_content_rw_t:sock_file { write create unlink getattr setattr };
allow httpd_t httpd_tmp_t:fifo_file { getattr setattr read create unlink };
allow httpd_t self:capability { setuid dac_read_search chown fsetid setgid fowner dac_override };
" > local.te

	checkmodule -M -m -o local.mod local.te
	semodule_package -o local.pp -m local.mod
	semodule -i local.pp
    fi
fi

/sbin/service mysqld start
/sbin/service memcached start

cd $WEBIVA_BASE_DIR

sudo -u $DEV_USER git clone git://github.com/cykod/Webiva.git

cd $WEBIVA_DIR

sudo -u $DEV_USER -s script/quick_install.rb

if ( selinuxenabled ); then
    if [ $ANSWER = 'y' ]; then
	chcon -R -h -t httpd_sys_content_t $WEBIVA_BASE_DIR
    fi
fi

/sbin/service httpd start

ANSWER=n
echo ""
echo ""
echo "Automatically start mysqld, memcached and httpd on boot (y/n):"
read -e ANSWER
if [ $ANSWER = 'y' ]; then
    chkconfig mysqld on
    chkconfig memcached on
    chkconfig httpd on
fi

if [ $RAILS_ENV = 'development' ]; then
    cd /home/$DEV_USER
    echo "127.0.0.1   $DOMAIN www.$DOMAIN" >> /etc/hosts
    sudo -u $DEV_USER ln -s $WEBIVA_DIR
fi
