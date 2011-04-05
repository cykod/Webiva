module Webiva
  class Bundler
    # Creates or recreates a Gemfile for Webiva on the fly.
    def self.setup
      self.create_gemfile if self.create_gemfile?
    end
    
    def self.tmp_gemfile
      @tmp_gemfile ||= "#{self.base_dir}/tmp/Gemfile"
    end

    def self.gemfiles
      @gemfiles ||= begin
        ["#{self.base_dir}/config/Gemfile"] +
        Dir.glob("#{self.base_dir}/vendor/modules/[a-z]*").collect do |dir|
          file = "#{dir}/Gemfile"
          File.exists?(file) ? file : nil
        end.compact
      end
    end

    def self.create_gemfile
      File.open(self.tmp_gemfile, "w") do |f|
        self.gemfiles.each do |file|
          f.write File.read(file)
        end
      end
    end
    
    def self.base_dir
      @base_dir ||= File.expand_path('../../', __FILE__)
    end
    
    # if we don't have a Gemfile or if another Gemfile is newer then the current one
    def self.create_gemfile?
      return true unless File.exists?(self.tmp_gemfile)
      last_updated_at = File.mtime self.tmp_gemfile
      self.gemfiles.detect { |file| last_updated_at < File.mtime(file) }
    end
  end
end
