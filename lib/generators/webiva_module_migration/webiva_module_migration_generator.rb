# Copyright (C) 2009 Pascal Rettig.




class WebivaModuleMigrationGenerator < Rails::Generator::NamedBase

  
  def manifest 
    @module_name = @name.underscore
    @name = args.shift.underscore
    record do |m|
      m.directory "/vendor/modules/#{@module_name}"
      
      m.migration_template('migration.rb', "/vendor/modules/#{@module_name}/db", 
                           :assigns => get_local_assigns,
                           :migration_file_name => @name)
      
    end
 
  end

  def banner
    "Usage: #{$0} #{spec.name} <module name> <migration file name>"
  end

  private  
    def get_local_assigns
      returning(assigns = {}) do
        if class_name.underscore =~ /^(add|remove)_.*_(?:to|from)_(.*)/
          assigns[:migration_action] = $1
          assigns[:table_name]       = $2.pluralize
        else
          assigns[:attributes] = []
        end
        assigns[:migration_name] = @name
      end
    end
end
