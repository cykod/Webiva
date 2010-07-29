namespace "cms" do 
  desc "Create an initial domain, domain database "
  task :initialize_system => [:environment] do |t|
	
    unless ENV["CLIENT"] && ENV["USERNAME"] && ENV["PASSWORD"] 
      print "Usage: CLIENT=client_name DOMAIN=domain USERNAME=username PASSWORD=password\n\n"
      return 
    end
    
    # Make sure the system is not already initialized
    if Client.find(:first) || Domain.find(:first)
      raise 'Initialize should only be called when initiallly setting up the CMS'
    end
    
    # Make an initial client
    client = Client.create(:name => ENV["CLIENT"],
                  :database_limit => 100,
                  :domain_limit => 1000);
                  
    # Make an initial client user who is a system admin
    client.client_users.create(:username => ENV["USERNAME"],
                                :password => ENV["PASSWORD"],
                                :client_admin => true,
                                :system_admin => true)
                                
    # Make the initial domain
    domain = client.domains.create(:name => ENV['DOMAIN'], :primary => true)
    
    print "Successfully Created Client, Domain and System User\n"
  end
end
