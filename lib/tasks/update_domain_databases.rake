
namespace "cms" do 
  desc "Update Domain Databases"
  task :update_domain_databases => [:environment] do |t|
    Domain.find(:all).each { |domain| domain.save_database_file }

    Client.find(:all).each do |client|
      client.max_file_storage = (client.num_databases * 10000) + 100000 if client.max_file_storage.nil?
      client.max_client_users = (client.num_databases * 10) + 100 if client.max_client_users.nil?
      client.domain_limit = client.num_databases + 10 if client.domain_limit.nil?
      client.save
    end
  end
end
