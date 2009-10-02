namespace "cms" do 
	desc "Create an initial System User"
	task :initialize_system_user  => [:environment] do |t|
	
    unless ENV["CLIENT"] && ENV["USERNAME"] && ENV["PASSWORD"] 
      print "Usage: CLIENT=client_name USERNAME=username PASSWORD=password\n\n"
      return 
    end
    client = Client.create(:name => ENV["CLIENT"],
                  :domain_limit => 10);
    client.client_users.create(:username => ENV["USERNAME"],
                                :password => ENV["PASSWORD"],
                                :client_admin => true,
                                :system_admin => true)
    client.domains.create(:name => CMS_DOMAIN)                          
    
    print "Successfully Created Client, Domain and System User\n"
	end
end