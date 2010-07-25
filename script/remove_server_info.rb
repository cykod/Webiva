#!/usr/bin/ruby


require 'yaml'

RAILS_ROOT = File.dirname(__FILE__) + "/.."

# We may not have a workling Webiva install, so 
def run_db_command(command)
   system("mysql",'-u',@username,"--password=#{@pw}","--host=#{@db_host}","--port=#{@db_port}",'-e',command,@db_name)
end


def remove_server_info

  cms_yml_file = YAML.load_file("#{RAILS_ROOT}/config/cms.yml")['production']

  @db_name= cms_yml_file['database']
  @username = cms_yml_file['username']
  @pw = cms_yml_file['password']
  @db_host = cms_yml_file['host']
  @db_port = 3306

  server_yml_file = YAML.load_file("#{RAILS_ROOT}/config/server.yml")['server']

  @server_name = server_yml_file['name']
  run_db_command("DELETE FROM `#{@db_name}`.`servers` WHERE hostname='#{@server_name}'")

end

remove_server_info


