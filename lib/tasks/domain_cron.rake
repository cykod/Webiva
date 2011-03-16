namespace "cms" do 

desc "Run a domains crons"
task :domain_cron => :environment do |t|

  if ENV['DOMAIN_ID']
    domains = Domain.find(:all, :conditions => ['id=? AND domain_type="domain" AND `database` != "" AND `status`="initialized"',ENV['DOMAIN_ID']]).collect {|dmn| dmn.get_info }
  else
    domains = Domain.find(:all,:conditions => 'domain_type = "domain" AND `database` != "" AND `status`="initialized"',
                          :group => '`database`').collect { |dmn| dmn.get_info }
  end
  
  now = Time.now
  current_hour = (ENV['HOUR'] || now.hour).to_i
  
  tm = Time.mktime(now.year,now.month,now.day,current_hour)
  
  domains.each do |dmn|
    print "Running #{current_hour} o' Clock Crons for Domain: #{dmn[:name]}\n"
    
    DomainModel.activate_domain(dmn)
    DataCache.reset_local_cache
    
    ContentType.update_site_index

    DomainLogSession.cron_update_sessions :hour => current_hour

    active_modules = SiteModule.find(:all,:conditions => "status IN ('active','initializing')")
    active_modules.each do |mod|
      crons = mod.admin_controller_class.get_module_crons
      
      crons.each do |cron|
        if cron[2][:hours].blank? || cron[2][:hours].include?(current_hour)
          print("    #{cron[1].humanize} - #{cron[0]}\n")
          begin
            cron[1].constantize.send(cron[0].to_sym,tm)
          rescue Exception => e
            print("ERROR RUNNING CRON - #{e.to_s}\n")
          end
        end
      end
    end
    
    print "\n"
  end
  
end

end
