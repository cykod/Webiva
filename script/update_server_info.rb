#!/usr/bin/ruby


require 'yaml'

RAILS_ROOT = File.dirname(__FILE__) + "/.."

# We may not have a workling Webiva install, so 
def run_db_command(command)
   system("mysql",'-u',@username,"--password=#{@pw}","--host=#{@db_host}","--port=#{@db_port}",'-e',command,@db_name)
end


def update_server_info

  cms_yml_file = YAML.load_file("#{RAILS_ROOT}/config/cms.yml")['production']

  @db_name= cms_yml_file['database']
  @username = cms_yml_file['username']
  @pw = cms_yml_file['password']
  @db_host = cms_yml_file['host']
  @db_port = 3306

  server_yml_file = YAML.load_file("#{RAILS_ROOT}/config/server.yml")['server']

  @server_name = server_yml_file['name']
  @roles = server_yml_file['roles'] || []
  
  @web_server = @roles.include?('web') ? 1 : 0
  @memcache_server = @roles.include?('memcache') ? 1 : 0 
  @starling_server = @roles.include?('starling') ? 1 : 0
  @workling_server = @roles.include?('workling') ? 1 : 0
  @cron_server = @roles.include?('cron') ? 1 : 0
  @master_db = @roles.include?('master_db') ? 1 : 0
  @domain_db = @roles.include?('domain_db') ? 1 : 0
  @slave_db = @roles.include?('slave_db') ? 1 : 0

  run_db_command("DELETE FROM `#{@db_name}`.`servers` WHERE hostname='#{@server_name}'")

  run_db_command("INSERT INTO `#{@db_name}`.`servers` (hostname, port, master_db, domain_db, slave_db, web, memcache, starling, workling, cron) VALUES('#{@server_name}', 80, #{@master_db}, #{@domain_db}, #{@slave_db}, #{@web_server}, #{@memcache_server}, #{@starling_server}, #{@workling_server}, #{@cron_server})")
end

update_server_info


