# Copyright (c) 2008 [Sur http://expressica.com]

require 'fileutils'

namespace :simple_captcha do
  desc "Set up the plugin SimpleCaptcha for rails < 2.0"
  task :setup_old => :environment do
    SimpleCaptcha::SetupTasks.do_setup(:old)
  end
  
  desc "Set up the plugin SimpleCaptcha for rails >= 2.0"
  task :setup => :environment do
    SimpleCaptcha::SetupTasks.do_setup
  end
end
