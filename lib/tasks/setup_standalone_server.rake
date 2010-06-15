
namespace "cms" do 
  desc "Setup a standalone server"
  task :setup_standalone_server => [:environment] do |t|
    Server.create_standalone unless Server.server_id

    raise "server id not set" unless Server.server_id

    domains = Domain.find(:all, :conditions => 'domain_type = "domain" AND `database` != "" AND `status`="initialized"').collect { |dmn| dmn.get_info }
    
    ActiveRecord::Base.logger = Logger.new(STDOUT)

    domains.each do |dmn|
      puts 'Updating server_id for Domain Files on ' + dmn[:name]
      db_file = dmn[:domain_database][:options]

      ActiveRecord::Base.establish_connection(db_file['production'])
      DomainModel.activate_domain(dmn, 'production')

      DomainFile.update_all "server_id = #{Server.server_id}"
    end
  end
end
