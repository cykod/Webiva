namespace "cms" do 
	desc "Migrate domain components"
	task :migrate_domain_components => [:environment] do |t|
	
    require 'active_record/schema_dumper'
    require 'logger'
    
    version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
    
    domain = ENV['DOMAIN_ID'] ? ENV["DOMAIN_ID"].to_i : nil
    
    components = ENV['COMPONENT'] || nil

    if components
     components = components.split(",").map(&:strip).reject(&:blank?)
    end 
    
    if domain
      domains = Domain.find(:all, :conditions => ['id=? AND domain_type="domain" AND `database` != "" AND (`status`="initialized" or `status` = "working")',domain]).collect {|dmn| dmn.get_info }
    else
      domains = Domain.find(:all,:conditions => 'domain_type = "domain" AND `database` != "" AND `status`="initialized"').collect { |dmn| dmn.get_info }
    end
    
    force = ENV['FORCE']
    
    
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    domains.each do |dmn|
      puts("\n\n")
      puts('***Migrating Components: ' + dmn[:name].to_s + "***")
      db_file = dmn[:domain_database][:options]
      ActiveRecord::Base.establish_connection(db_file['migrator'])
      DomainModel.activate_domain(dmn,'migrator')
      #DomainModel.establish_connection(db_file['migrator'])

      ComponentMigrator.handle_migration_update
      
      if force && domain
        components = Dir.glob("#{RAILS_ROOT}/vendor/modules/*/db").map { |md| md.split("/")[-2] } unless components
        components.each do |component|
          dir = "#{RAILS_ROOT}/vendor/modules/#{component}/db"
          ComponentMigrator.current_component = component
      	  ComponentMigrator.migrate(dir,version)
        end
      else
        active_modules = SiteModule.find(:all,:conditions => "status IN ('active','initializing','initialized','error')")
        active_modules.each do |mod|
          dir = "#{RAILS_ROOT}/vendor/modules/#{mod.name}/db"
          if(File.directory?(dir) && (!components || components.include?(mod.name)))
            begin
              ComponentMigrator.current_component = mod.name
              ComponentMigrator.migrate(dir,version)
              mod.update_attribute(:status,'initialized') if mod.status == 'initializing' || mod.status == 'error'
            rescue Exception => e
              if mod.status == 'initializing'
                mod.update_attribute(:status,'error')
              else
                raise e
              end
            end
          elsif (!components || components.include?(mod.name))
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
