#!/usr/bin/env ruby

require 'sha1'
require 'base64'
require 'fileutils'
require 'yaml'
require 'rubygems'
require 'memcache'

RAILS_ROOT = File.dirname(__FILE__) + "/.."

def run_db_command(command,use_db=true)
     if use_db
       system("mysql",'-u',@username,"--password=#{@pw}","--host=#{@db_host}","--port=#{@db_port}",'-e',command,@db_name)
     else
       system("mysql",'-u',@username,"--password=#{@pw}","--host=#{@db_host}","--port=#{@db_port}",'-e',command)
     end
end


class WebivaQuickInstall


  def initialize(input)
    @input = input
  end
  

  def run
    display_introduction()
    case get_server_type()
    when 'standalone'
      run_standalone_install()
    when 'master'
      run_master_server_install()
    when 'slave'
      run_slave_server_install()
    end
  end

  private

  # Add unix console styles to strings
  # default is underline & bold
  # for more styles see http://snippets.dzone.com/posts/show/4822
  def wrap(str, style="\033[4m\033[1m")
    "#{style}#{str}\033[0m"
  end


  def run_standalone_install
    get_server_name()
    get_mysql_user_and_db_name()
    create_master_database()
    create_master_users()
    create_initial_yml_files()
    validate_memcache_servers()
    rebuild_gems()
    migrate_system_db()
    initialize_system()
    create_domain_db()
    display_success_message()
  end

  def run_master_server_install
    get_server_name()
    get_mysql_user_and_db_name()
    create_master_database()
    create_master_users()
    create_initial_yml_files()
    validate_memcache_servers()
    rebuild_gems()
    migrate_system_db()
    initialize_system()
    create_domain_db()
    add_server_to_db()
    display_success_message()
  end

  def run_slave_server_install
    get_server_name()
    validate_configs_exists()
    validate_memcache_servers()
    rebuild_gems()
    add_server_to_db()
    display_success_message()
  end

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

  def whoami
    ENV['USER']
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
    @db_host = 'localhost'
    @db_port = 3306
    if @server_type == 'master'
      @db_host = input_value("Mysql host (#{@server_name}):",@server_name)
      report_error @db_host != 'localhost', "Mysql host can not be localhost for the master server"
      @db_port = input_value("Mysql port (#{@db_port}):",@db_port)
    end
  end

  def get_server_type()
    @server_type = 'standalone'
    @server_type = input_value("Type of server Standalone/#{wrap('M')}aster/#{wrap('S')}lave (#{@server_type}):", @server_type).downcase
    case @server_type
    when 'm'
      @server_type = 'master'
    when 's'
      @server_type = 'slave'
    end
    report_error(@server_type == 'standalone' || @server_type == 'master' || @server_type == 'slave', "Invalid server type")
    @server_type
  end

  def get_server_name()
    if @server_type == 'standalone'
      @server_name = 'localhost'
    else
      @server_name = `hostname`.strip
      @server_name = input_value("#{@server_type.capitalize} server host name (#{@server_name}):", @server_name)
      report_error(@server_name != 'localhost', "Master server can not be localhost") if @server_type == 'master'
    end

    if File.exists?("#{RAILS_ROOT}/config/server.yml")
      puts('server.yml already exists, not overwriting')
    else
      FileUtils.cp("#{RAILS_ROOT}/config/server.yml.example","#{RAILS_ROOT}/config/server.yml")
    end

    server_yml_file = YAML.load_file "#{RAILS_ROOT}/config/server.yml"
    server_yml_file['server']['name'] = @server_name
    server_yml_file['server']['type'] = @server_type
    File.open("#{RAILS_ROOT}/config/server.yml","w") { |fd| fd.write(YAML.dump(server_yml_file)) }
  end

  def add_server_to_db()
    return if @server_type == 'standalone'

    ok = true

    if @server_type == 'master'
      ok = run_db_command("INSERT INTO `#{@db_name}`.`servers` (hostname, port, master_db, domain_db, slave_db, web, memcache, starling, workling, cron) VALUES('#{@server_name}', 80, 1, 1, 0, 0, 1, 1, 0, 1)")
    elsif @server_type == 'slave'
      ok = run_db_command("INSERT INTO `#{@db_name}`.`servers` (hostname, port, master_db, domain_db, slave_db, web, memcache, starling, workling, cron) VALUES('#{@server_name}', 80, 0, 0, 0, 1, 0, 0, 1, 0)")
    end

    report_error(ok,"Error adding #{@server_type} server to #{@db_name}.servers table")
  end

  def validate_memcache_servers()
    defaults_config_file = YAML.load_file("#{RAILS_ROOT}/config/defaults.yml")

    memcache_servers = defaults_config_file['memcache_servers'] || ['localhost:11211']
    memcache_servers.each do |server|
      report_error(server != 'localhost:11211', "Invalid memcache server #{server} for Webiva master/slave setup") unless @server_type == 'standalone'
      client = MemCache.new server
      begin
        client.set 'validate_memcache_servers', 1
        report_error client.get('validate_memcache_servers') == 1, "Failed to connect to memcache server #{server}"
        client.delete 'validate_memcache_servers'
      rescue Exception => e
        report_error false, "Failed to connect to memcache server #{server}, #{e}"
      end
    end
  end

  def validate_configs_exists()
    files = %w(cms.yml cms_migrator.yml defaults.yml workling.yml)
    files.each do |file|
      filename = "#{RAILS_ROOT}/config/#{file}"
      cmd = "scp #{files.join(' ')} #{whoami}@#{@server_name}:#{File.expand_path(RAILS_ROOT + '/config')}"
      report_error File.exists?(filename), "config/#{file} not found!\nCopy the config files from the Master server.\n#{wrap(cmd, "\033[1m")}"
    end

    cms_migrator_yml_file = YAML.load_file "#{RAILS_ROOT}/config/cms_migrator.yml"
    @username = cms_migrator_yml_file['production']['username']
    @pw = cms_migrator_yml_file['production']['password']
    @db_name = cms_migrator_yml_file['production']['database']
    @db_host = cms_migrator_yml_file['production']['host']
    @db_port = cms_migrator_yml_file['production']['port']
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

    ok = run_db_command("GRANT SELECT,INSERT,UPDATE,DELETE ON  #{@db_name}.*  to '#{@db_name_short}_u'@'%' identified by '#{@user_password}'",false)
    report_error(ok,"Error creating master db user")

    # Create the initial migrator user
    ok = run_db_command("grant  all on *.* to '#{@db_name_short}_m'@localhost identified by '#{@migrator_password}' WITH GRANT OPTION")
    report_error(ok,"Error creating master db migrator user")

    ok = run_db_command("grant  all on *.* to '#{@db_name_short}_m'@'%' identified by '#{@migrator_password}' WITH GRANT OPTION")
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

      if @server_type == 'master'
        defaults_yml_file = YAML.load_file "#{RAILS_ROOT}/config/defaults.yml"
        defaults_yml_file['memcache_servers'] = ["#{@server_name}:11211"]
        File.open("#{RAILS_ROOT}/config/defaults.yml","w") { |fd| fd.write(YAML.dump(defaults_yml_file)) }
      end
    end

    print('Creating cms.yml...')

    @db_socket = `mysql_config --socket`.to_s.strip

    if @db_socket.to_s == ''
      @db_socket = File.exists?('/var/lib/mysql/mysql.sock') ? '/var/lib/mysql/mysql.sock' : '/var/run/mysqld/mysqld.sock'
      @db_socket = File.exists?(@db_socket) ? @db_socket : '/tmp/mysql.sock'
    end


 
    if !File.exists?(@db_socket)
      
      @db_socket = input_value("Mysql Socket","/var/lib/mysql/mysql.sock")
    end
    write_db_yml_file('cms.yml', { 'username' => "#{@db_name_short}_u" ,'password' => @user_password, 'database'  => @db_name, 'host' => @db_host, 'port' => @db_port, 'socket' => @db_socket })
    print("Done!\n")

    print('Creating cms_migrator.yml...')
    write_db_yml_file('cms_migrator.yml',  { 'username' => "#{@db_name_short}_m" ,'password' => @migrator_password, 'database' => @db_name, 'host' => @db_host, 'port' => @db_port, 'socket' => @db_socket })
    print("Done!\n")

    print('Creating workling.yml...')
    workling_yml_file = YAML.load_file("#{RAILS_ROOT}/config/workling.yml")
    workling_yml_file['production']['listens_on'] = "#{@server_name}:15151"
    workling_yml_file['development']['listens_on'] = "#{@server_name}:22122"
    File.open("#{RAILS_ROOT}/config/workling.yml","w") { |fd| fd.write(YAML.dump(workling_yml_file)) }
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
    puts('Installing additional gems...')
    ok = system('rake gems:install')
    report_error(ok,'Could not install gems (run "rake --trace gems:install" manually to see errors)')
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
