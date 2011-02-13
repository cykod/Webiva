# Copyright (C) 2009 Pascal Rettig.


class WebivaRendererGenerator < Rails::Generator::NamedBase
  attr_accessor :module_name, :renderer_name, :module_path, :renderer_path, :module_class, :renderer_class, :paragraphs
  
  
  def manifest 
    @module_path,@renderer_path = @name.gsub(/^\//,'').split("/")
    
    @module_class = @module_path.camelcase
    @renderer_class = @renderer_path.camelcase
    
    @module_name = @module_class.underscore.humanize.titleize
    @renderer_name = @renderer_path.humanize
    
    @paragraphs = (args||[]).map { |para| para.underscore }
      
    record do |m|
      m.template 'renderer/controller.rb', "/vendor/modules/#{module_path}/app/controllers/#{module_path}/#{renderer_path}_controller.rb"
      m.template 'renderer/feature.rb', "/vendor/modules/#{module_path}/app/controllers/#{module_path}/#{renderer_path}_feature.rb"
      m.template 'renderer/renderer.rb', "/vendor/modules/#{module_path}/app/controllers/#{module_path}/#{renderer_path}_renderer.rb"
    end
  end

  def banner
    "Usage: #{$0} #{spec.name} <module path>/<renderer path> [<paragraphs>]"
  end
end
