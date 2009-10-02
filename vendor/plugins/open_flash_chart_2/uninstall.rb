puts "Removing files from public directory:"
FileUtils.rm "#{RAILS_ROOT}/public/javascripts/swfobject.js"
FileUtils.rm "#{RAILS_ROOT}/public/open-flash-chart.swf"
puts "Plugin uninstalled."
