require 'fileutils'
require 'active_record'

namespace "cms" do 

desc "Run a domain task"
task :install_module => [:environment] do |t|

  
  if ENV['MODULE'].blank?
      raise "USAGE: rake cms:install_module MODULE=mod_name"
  end
  
    `cd #{Rails.root}/vendor/modules; git clone #{GIT_REPOSITORY}Webiva-#{ENV['MODULE']}.git #{ENV['MODULE']}`
end

end
