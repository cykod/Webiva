# Copyright (C) 2009 Pascal Rettig.




class WebivaModuleGenerator < Rails::Generator::NamedBase
  attr_accessor :class_title

  def manifest 
    @name = @name.underscore

    @class_title = class_name.underscore.humanize.titleize

    record do |m|
      m.directory "/vendor/modules/#{@name}"
      m.file "init.rb","/vendor/modules/#{@name}/init.rb"
      
      m.directory "/vendor/modules/#{@name}/app/controllers/#{@name}"
      m.directory "/vendor/modules/#{@name}/app/models"
      m.directory "/vendor/modules/#{@name}/app/views/#{@name}/admin"
      
      m.template "admin_controller.rb","/vendor/modules/#{@name}/app/controllers/#{@name}/admin_controller.rb"
      m.template "options.rhtml","/vendor/modules/#{@name}/app/views/#{@name}/admin/options.rhtml"
    end
  
  end

  def banner
    "Usage: #{$0} #{spec.name} <module name>"
  end
end
