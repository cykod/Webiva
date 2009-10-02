namespace :open_flash_chart_2 do
  PLUGIN_ROOT = File.dirname(__FILE__) + '/../'

  desc 'Installs required swf in public/ and javascript files to the public/javascripts directory.'
  task :install do
    FileUtils.cp "#{PLUGIN_ROOT}requirements/open-flash-chart.swf", "#{RAILS_ROOT}/public", :verbose => true
    FileUtils.cp "#{PLUGIN_ROOT}requirements/swfobject.js", "#{RAILS_ROOT}/public/javascripts", :verbose => true
    # don't copy json.js file, it's seems tjat everything works without that file
    #    FileUtils.cp "#{PLUGIN_ROOT}/requirements/json/*.js", "#{RAILS_ROOT}/public/javascripts", :verbose => true
  end
  desc 'Removes the swf and javascripts for the plugin.'
  task :uninstall do
    FileUtils.rm "#{RAILS_ROOT}/public/javascripts/swfobject.js", :force => true, :verbose => true
    FileUtils.rm "#{RAILS_ROOT}/public/open-flash-chart.swf", :force => true, :verbose => true
  end
end