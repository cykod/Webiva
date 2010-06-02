
namespace "cms" do 
  desc "Initialize a Domain Database"
  task :create_domain_db => [:environment] do |t|
    domain_id = ENV['DOMAIN_ID'] || raise('Missing DOMAIN_ID=## argument')
    DomainDatabase.create_domain_db domain_id
  end
end
