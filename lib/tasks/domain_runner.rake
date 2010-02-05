namespace "cms" do 

desc "Run a domain task"
task :domain_runner => :environment do |t|

  unless (ENV['DOMAIN']||ENV['DOMAIN_ID']) && ENV['CLASS'] && ENV['METHOD']
    raise 'USAGE: rake cms:domain_runner DOMAIN=DOMAIN_ID CLASS=CLASS_NAME METHOD=METHOD_NAME'
  end

  DomainModel.activate_domain((ENV['DOMAIN']||ENV['DOMAIN_ID']).to_i) 
  DataCache.reset_local_cache
  
  cls = ENV['CLASS'].constantize
  
  mthd = ENV['METHOD']
  
  cls.send(mthd)
  
end

end
