
namespace "cms" do 
  desc "Update Domain Databases"
  task :update_domain_databases => [:environment] do |t|
    Domain.find(:all).each { |domain| domain.save_database_file }
  end
end
