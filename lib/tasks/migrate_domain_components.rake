namespace "cms" do 
	desc "Migrate domain components"
	task :migrate_domain_components => [:environment] do |t|
	
    require 'active_record/schema_dumper'
    require 'logger'
    
    version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
    
    domain = ENV['DOMAIN_ID'] ? ENV["DOMAIN_ID"].to_i : nil
    
    component = ENV['COMPONENT'] || nil
    
    if domain
      domains = Domain.find(:all, :conditions => ['id=? AND domain_type="domain" AND `database` != "" AND `status`="initialized"',domain]).collect {|dmn| dmn.attributes }
    else
      domains = Domain.find(:all,:conditions => 'domain_type = "domain" AND `database` != "" AND `status`="initialized"').collect { |dmn| dmn.attributes }
    end
    
    force = ENV['FORCE']
    
    
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    domains.each do |dmn|
      print('Migrating Components: ' + dmn['name'].to_s)
      db_file = YAML.load_file("#{RAILS_ROOT}/config/sites/#{dmn['database']}.yml")
      ActiveRecord::Base.establish_connection(db_file['migrator'])
      DomainModel.establish_connection(db_file['migrator'])
      ComponentMigrator.handle_migration_update
      
      if force && domain
        dir = "#{RAILS_ROOT}/vendor/modules/#{component}/db"
        ComponentMigrator.current_component = component
    	  ComponentMigrator.migrate(dir,version)
      else
        active_modules = SiteModule.find(:all,:conditions => "status IN ('active','initializing')")
        active_modules.each do |mod|
          dir = "#{RAILS_ROOT}/vendor/modules/#{mod.name}/db"
          if(File.directory?(dir) && (!component || component == mod.name))
            mod.update_attribute(:status,'initialized') if mod.status == 'initializing'
            ComponentMigrator.current_component = mod.name
        	  ComponentMigrator.migrate(dir,version)
          elsif (!component || component == mod.name)
            mod.update_attribute(:status,'initialized') if mod.status == 'initializing'
          end
        end
      end
      
      DataCache.expire_container('SiteNode')
      DataCache.expire_container('SiteNodeModifier')
      DataCache.expire_content
      
    end 
    
  end

end
