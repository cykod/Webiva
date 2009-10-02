puts "Copying files to public directory:"
PLUGIN_ROOT = File.dirname(__FILE__) + '/../'
FileUtils.cp "#{PLUGIN_ROOT}requirements/*.swf", "#{RAILS_ROOT}/public", :verbose => true
FileUtils.cp "#{PLUGIN_ROOT}requirements/*.js", "#{RAILS_ROOT}/public/javascripts", :verbose => true
puts "Plugin installed."
puts "Please read README file."