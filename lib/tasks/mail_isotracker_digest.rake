desc "Mail the isotracker digest to destination users"
task :mail_isotracker_digest => [:environment] do |t|

  require 'active_record/schema_dumper'
  require 'logger'
  
  domain = ENV["DOMAIN"] || raise('Please add a DOMAIN argument to specify the desired domain') 
  
  db_config = YAML.load_file("#{RAILS_ROOT}/config/cms.yml")
  
  main_db = YAML.load_file("#{RAILS_ROOT}/config/database.yml")
  
  domain_db_info = db_config["domain_db"]
  
  class DomainList < ActiveRecord::Base
    set_table_name :domains
  end
  
  ActiveRecord::Base.establish_connection(main_db[RAILS_ENV])
  
  domains = [ domain ]
  
  domains.each do |domain| 
  
    domain_db = "cms_" + domain.sub("." , "_")
  
    domain_db_info["database"] = domain_db;
    #ActiveRecord::Base.logger = Logger.new(STDOUT)
    DomainModel.establish_connection(domain_db_info)
  
    print "Sending Isotracker Digest Domain: #{domain}\n"
    
    Isotracker::DailyDigestMailer.send_digest()
  end


end