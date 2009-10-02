namespace :backgroundrb do
  require 'yaml'
  desc 'Setup backgroundrb in your rails application'
  task :setup do
    script_dest = "#{RAILS_ROOT}/script/backgroundrb"
    script_src = File.dirname(__FILE__) + "/../script/backgroundrb"

    FileUtils.chmod 0774, script_src

    defaults = {:host => 'localhost', 
                :port => 2000,
                :rails_env => 'development'
               }

    config_dest = "#{RAILS_ROOT}/config/backgroundrb.yml" 
             
    unless File.exists?(config_dest)
        puts "Copying backgroundrb.yml config file to #{config_dest}"
        File.open(config_dest, 'w') { |f| f.write(YAML.dump(defaults)) }
    end          

    unless File.exists?(script_dest)
        puts "Copying backgroundrb script to #{script_dest}"
        FileUtils.cp_r(script_src, script_dest)
    end

    workers_dest = "#{RAILS_ROOT}/lib/workers"
    unless File.exists?(workers_dest)
        puts "Creating #{workers_dest}"
        FileUtils.mkdir(workers_dest)
    end
  end

  desc 'Remove backgroundrb from your rails application'
  task :remove do
    script_src = "#{RAILS_ROOT}/script/backgroundrb"

    if File.exists?(script_src)
        puts "Removing #{script_src} ..."
        FileUtils.rm(script_src, :force => true)
    end

    workers_dest = "#{RAILS_ROOT}/lib/workers"
    if File.exists?(workers_dest) && Dir.entries("#{workers_dest}").size == 2
        puts "#{workers_dest} is empty...deleting!"
        FileUtils.rmdir(workers_dest)
    end
  end


  desc 'Start backgroundrb server (default values)'
  task :start do
    def disabled_warning
      puts "WARNING: the rake tasks for start/stop/restart of BackgrounDRb is currently broken"
      puts "WARNING: use ./script/backgroundrb start/stop instead"
      puts "WARNING: http://backgroundrb.devjavu.com/projects/backgroundrb/ticket/27"
    end
    script = "#{RAILS_ROOT}/script/backgroundrb"

    if File.exists?(script)
      disabled_warning
      #`#{script} start`
    else
      puts "Backgroundrb is not installed. Run 'rake backgroundrb:setup' first!"
    end
  end

  desc 'Stop backgroundrb server (default values)'
  task :stop do
    script = "#{RAILS_ROOT}/script/backgroundrb"

    if File.exists?(script)
      disabled_warning
      #`#{script} stop`
    else
      puts "Backgroundrb is not installed. Run 'rake backgroundrb:setup' first!"
    end
  end

  # HACK: We don't have restart implemented in the backgroundrb server
  # yet
  desc 'Restart backgroundrb server (default values)'
  task :restart do
    script = "#{RAILS_ROOT}/script/backgroundrb"

    if File.exists?(script)
      disabled_warning
      #`#{script} stop`
      #`sleep 2`
      #`#{script} start`
    else
      puts "Backgroundrb is not installed. Run 'rake backgroundrb:setup' first!"
    end
  end
end
