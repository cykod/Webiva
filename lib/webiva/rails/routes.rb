module ActionDispatch::Routing
  class Mapper
    def webiva_module_for(mod_name)
      namespace mod_name do
        webiva_module_controllers(mod_name).each do |cntl|
          match "/#{cntl}(/:action(/*path))", :controller => cntl
        end
      end
    end
      
    def webiva_module_controllers(mod_name)
      base_dir = webiva_module_base_dir(mod_name)
      ext = "_controller.rb"
      Dir.glob("#{base_dir}[a-z]*#{ext}").collect { |file| file.sub(base_dir, '').sub(ext, '') }.sort
    end
    
    def webiva_module_base_dir(mod_name)
      "#{Rails.root}/vendor/modules/#{mod_name}/app/controllers/#{mod_name}/"
    end
    
    # Each webiva module can add in their own specific routes by adding a webiva_<module name>_routes method to ActionDispatch::Routing::Mapper
    def webiva_module_routes(mod_name)
      routes_file = "#{webiva_module_base_dir(mod_name)}lib/#{mod_name}/rails/routes.rb"
      return unless File.exists?(routes_file)
      require routes_file
      self.send("webiva_#{mod_name}_routes") if self.respond_to?("webiva_#{mod_name}_routes")
    end

    def webiva_controller_base_dir
      "#{Rails.root}/app/controllers/"
    end
    
    def webiva_base_controllers
      base_dir = webiva_controller_base_dir
      ext = "_controller.rb"
      Dir.glob("#{base_dir}[a-z]*#{ext}").collect { |file| file.sub(base_dir, '').sub(ext, '') }.sort
    end

    def webiva_controllers_for(subdir)
      base_dir = "#{webiva_controller_base_dir}#{subdir}/"
      ext = "_controller.rb"
      Dir.glob("#{base_dir}[a-z]*#{ext}").collect { |file| file.sub(base_dir, '').sub(ext, '') }.sort
    end

    def webiva_modules
      base_dir = "#{Rails.root}/vendor/modules/"
      Dir.glob("#{base_dir}[a-z]*").collect { |dir| File.directory?(dir) ? dir.sub(base_dir, '') : nil }.compact.sort
    end
  end
end
