#!/usr/bin/ruby

require 'sha1'
require 'base64'
require 'fileutils'
require 'yaml'

RAILS_ROOT = File.dirname(__FILE__) + "/.."

def run_db_command(command,use_db=true)
     if use_db
       system("mysql",'-u',@username,"--password=#{@pw}",'-e',command,@db_name)
     else
       system("mysql",'-u',@username,"--password=#{@pw}",'-e',command)
     end
end


class WebivaQuickInstall


  def initialize(input)
    @input = input
  end
  

  def run
    display_introduction()
    get_mysql_user_and_db_name()
    create_master_database()
    create_master_users()
    create_initial_yml_files()
    rebuild_gems()
    migrate_system_db()
    initialize_system()
    create_domain_db()

    display_success_message()
  end

  private

  def report_error(ok,msg)
    return if ok
    puts(msg);
    exit(1)
  end


  def input_value(str,default='')
    print(str)
    val = @input.gets.strip
    val = default if val.to_s == ''
    val
  end

  protected

  def display_introduction
    puts( <<-INTRODUCTION)


Webiva Quick Installer
======================

This script will create the initial configuration files for Webiva
( cms.yml, cms_migrator.yml, workling.yml and defaults.yml )
and initialize the mater database and an initial site database to get
you started.

First thing first, we need the user name and password of a mysql user
that has admin access and can create the initial Webiva database and
grant permissions for webiva specific users:

INTRODUCTION

  end

  def get_mysql_user_and_db_name()
    @username = input_value("Mysql Admin User name (root):",'root')
    @pw = input_value("Mysql Admin User password ([blank]):",'')
    @db_name = input_value("Master database name (webiva):",'webiva')
    @db_name_short = @db_name[0..12] # Max mysql user name is 16 char and we add a suffix 

  end

  def create_master_database
    ok = run_db_command( "create database `#{@db_name}`",false)
    report_error(ok,"Error creating database: #{@db_name}")
  end

  def create_master_users
    
    @user_password =  Base64.encode64(Digest::SHA1.hexdigest("#{rand(1<<64)}/#{Time.now.to_f}/#{Process.pid}"))[0..7]
    @migrator_password = Base64.encode64(Digest::SHA1.hexdigest("#{rand(1<<64)}/#{Time.now.to_f}/#{Process.pid}"))[0..7]


    # Create the initial webiva database user
    ok = run_db_command("GRANT SELECT,INSERT,UPDATE,DELETE ON  #{@db_name}.*  to '#{@db_name_short}_u'@localhost identified by '#{@user_password}'",false)

    report_error(ok,"Error creating master db user")

    # Create the initial migrator user
    ok = run_db_command("grant  all on *.* to '#{@db_name_short}_m'@localhost identified by '#{@migrator_password}' WITH GRANT OPTION")

    report_error(ok,"Error creating master db migrator user")
  end

  def create_initial_yml_files

    if File.exists?("#{RAILS_ROOT}/config/workling.yml")
      puts('workling.yml already exists, not overwriting')
    else
      FileUtils.cp("#{RAILS_ROOT}/config/workling.yml.example","#{RAILS_ROOT}/config/workling.yml")
    end

    if File.exists?("#{RAILS_ROOT}/config/defaults.yml")
      puts("defaults.yml already exists, not overwriting")
    else
       FileUtils.cp("#{RAILS_ROOT}/config/defaults.yml.example","#{RAILS_ROOT}/config/defaults.yml")
    end

    print('Creating cms.yml...')
    @db_socket = File.exists?('/var/lib/mysql/mysql.sock') ? '/var/lib/mysql/mysql.sock' : '/var/run/mysqld/mysqld.sock'
    write_db_yml_file('cms.yml', { 'username' => "#{@db_name_short}_u" ,'password' => @user_password, 'database'  => @db_name, 'socket' => @db_socket })
    print("Done!\n")

    print('Creating cms_migrator.yml...')
    write_db_yml_file('cms_migrator.yml',  { 'username' => "#{@db_name_short}_m" ,'password' => @migrator_password, 'database' => @db_name, 'socket' => @db_socket })
    print("Done!\n")
  end


  def write_db_yml_file(filename,args)

    cms_yml_example_file = YAML.load_file("#{RAILS_ROOT}/config/#{filename}.example")
    %w(adapter socket host encoding pool).each do |arg|
      args[arg] ||= cms_yml_example_file['production'][arg]
    end

    cms_yml_output_file = { 'production' => args, 'development' => args }
    File.open("#{RAILS_ROOT}/config/#{filename}","w") { |fd| fd.write(YAML.dump(cms_yml_output_file)) }
  end

  def rebuild_gems
    puts('Rebuilding local gems...')
    ok = system('rake gems:build:force')
    report_error(ok,'Could not build local gems (run "rake --trace gems:build:force" manually to see errors)')
    puts('Done rebuildings local gems...')
  end


  def migrate_system_db()
    ok = system('rake cms:migrate_system_db')
    report_error(ok,'Could not migrate system database (run "rake --trace cms:migrate_system_db" manually to see errors')
  end

  def initialize_system()

    puts(<<-EOF)
To initialize the system, Webiva needs a client name (the name of the first client on the system), a domain name (the name of the first domain to create on the system) and an initial Super Admin username and password.

Since Webiva will always check the domain name sent to the system you may want to edit your /etc/hosts file to point a dummy domain to your localhost for testing purposes, a line like:
 127.0.0.1 mywebiva.com www.mywebiva.com
Should do the trick (change the domain to something else if you modify the initial domain name)

EOF

    @client_name = input_value('Client Name (Master):','Master').gsub(" ","\\ ")
    @domain = input_value('Initial Domain (mywebiva.com):','mywebiva.com').gsub(" ","\\ ")
    @admin_username = input_value('Admin username (admin):','admin').gsub(" ","\\ ")

    @default_admin_password =  Base64.encode64(Digest::SHA1.hexdigest("#{rand(1<<64)}/#{Time.now.to_f}/#{Process.pid}"))[0..5]
    @admin_password = input_value("Admin password (#{@default_admin_password}):",@default_admin_password).gsub(" ","\\ ")

    
    cmd = "rake --trace cms:initialize_system CLIENT=#{@client_name} DOMAIN=#{@domain} USERNAME=#{@admin_username} PASSWORD=#{@admin_password}"
    ok = system(cmd)

    report_error(ok,"Error initializing system, please run: #{cmd} manually")
  end

  def create_domain_db
    ok = system("rake cms:create_domain_db DOMAIN_ID=1")

    report_error(ok,"Error creating initial domain database, please run 'rake --trace cms:create_domain_db DOMAIN_ID=1' manually to see errors")
    
  end

  def build_local_gems
    print("Building local gems")

    system("find #{RAILS_ROOT}/vendor/gems '*.o' -print | xargs rm")
    system("find #{RAILS_ROOT}/vendor/gems '*.so' -print | xargs rm")
    system("find #{RAILS_ROOT}/vendor/gems '*.out' -print | xargs rm")

    ok = system("rake gems:build:force")
    report_error(ok,'building of local gems failed, please run rake --trace gems:build:force manually')
  end

  def display_success_message

    puts("\n" + <<-EOF)
Webiva has (hopefully) been installed and set up correctly. You should be able to run:
./script/server 
from the top level directory to start up a server on port 3000 and
you should be able to access the system from:
http://#{@domain}:3000/website
using the admin username and password you just entered:

Username: #{@admin_username}
Password: #{@admin_password}

If everything looks good, follow the remaining instructions in 
doc/INSTALL to get yourself integrated into apache with Phusion Passenger(tm).

Good Luck and Happy CMS'ing!
EOF
  end
end



install = WebivaQuickInstall.new(STDIN)
install.run
