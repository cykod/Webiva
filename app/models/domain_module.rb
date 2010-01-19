# Copyright (C) 2009 Pascal Rettig.

# DomainModule is a SystemModel that controls module availablility on individual databases
# It is only hit to check availability, SiteModule is the DomainModel class that holds the
# active Modules
class DomainModule < SystemModel

  belongs_to :domain
  
  # Return information about module availability on a single Domain object
  def self.module_info(domain,module_name)
        # Get the class constant
        module_class = "#{module_name.camelcase}::AdminController".constantize
        
        # Get the DomainModule entry
        module_entry  = domain.domain_modules.find_by_name(module_name)
        module_entry||= DomainModule.new( :name => module_name, :access => 'none' )
        
        # Get the info about the whole
        component_info = module_class.get_component_info
        
        module_status= :unavailable
        case module_entry.access
        when 'none':
          if component_info[1][:access].to_sym == 'hidden'
            module_status='hidden'
          else
            module_status = component_info[1][:access].to_sym == :private ? 'unavailable' : 'available' 
          end
        when 'available':
          module_status = 'available'
        when 'unavailable':
          module_status = 'unavailable'
        end
        
        { :module => module_name,
          :name  => component_info[0],
          :description => component_info[1][:description],
          :dependencies =>  component_info[1][:dependencies] || [],
          :status => module_status
        }
  end
  
  # Return a list of a modules on a Domain object that
  # aren't hidden
  def self.all_modules(domain)
    modules = []
    Dir.glob("#{RAILS_ROOT}/vendor/modules/[a-z0-9_]*") do |file|
      if file =~ /\/([a-z_0-9-]+)\/{0,1}$/
        mod = self.module_info(domain,$1)
        modules <<  mod if mod[:status] != 'hidden'
      end
    end
    modules
  end    
  
  
end
