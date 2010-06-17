
namespace "cms" do 
  desc "Setup a standalone server"
  task :setup_standalone_server => [:environment] do |t|
    Server.create_standalone unless Server.server_id

    raise "server id not set" unless Server.server_id

    ActiveRecord::Base.logger = Logger.new(STDOUT)

    Domain.each do |domain|
      puts 'Updating server_id for Domain Files on ' + domain[:name]
      DomainFile.update_all "server_id = #{Server.server_id}", "server_id is NULL"
      DomainFileVersion.update_all "server_id = #{Server.server_id}", "server_id is NULL"
    end
  end
end
