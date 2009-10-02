require 'fileutils'

module SimpleCaptcha #:nodoc
  module SetupTasks #:nodoc

    def self.do_setup(version = :new)
      @version = version

      begin
        puts "STEP 1"
        generate_migration
        write_migration_content
        copy_view_file
        puts "Followup Steps"
        puts "STEP 2 -- run the task 'rake db:migrate'"
        puts "STEP 3 -- edit the file config/routes.rb to add the route \"map.simple_captcha '/simple_captcha/:action', :controller => 'simple_captcha'\""
      rescue StandardError => e
        p e
      end
    end

    private

    def self.generate_migration
      puts "==============================================================================="
      puts "ruby script/generate migration create_simple_captcha_data"
      puts %x{ruby script/generate migration create_simple_captcha_data}
      puts "================================DONE==========================================="
    end
  
    def self.migration_source_file
      @version == :old ?
      File.join(File.dirname(__FILE__), "../assets", "migrate", "create_simple_captcha_data_less_than_2.0.rb") :
      File.join(File.dirname(__FILE__), "../assets", "migrate", "create_simple_captcha_data.rb")
    end

    def self.write_migration_content
      copy_to_path = File.join(RAILS_ROOT, "db", "migrate")
      migration_filename = 
        Dir.entries(copy_to_path).collect do |file|
          number, *name = file.split("_")
          file if name.join("_") == "create_simple_captcha_data.rb"
        end.compact.first
      migration_file = File.join(copy_to_path, migration_filename)
      File.open(migration_file, "wb"){|f| f.write(File.read(migration_source_file))}
    end

    def self.copy_view_file
      puts "Copying SimpleCaptcha view file."
      mkdir(File.join(RAILS_ROOT, "app/views/simple_captcha")) unless File.exist?(File.join(RAILS_ROOT, "app/views/simple_captcha"))
      view_file = @version == :old ? '_simple_captcha.rhtml' : '_simple_captcha.erb'
      FileUtils.cp_r(
        File.join(File.dirname(__FILE__), "../assets/views/simple_captcha/_simple_captcha.erb"),
        File.join(RAILS_ROOT, "app/views/simple_captcha/", view_file)
      )
      puts "================================DONE==========================================="
    end
  end
end
