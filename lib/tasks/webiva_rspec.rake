rspec_gem_dir = nil
Dir["#{RAILS_ROOT}/vendor/gems/*"].each do |subdir|
  rspec_gem_dir = subdir if subdir.gsub("#{RAILS_ROOT}/vendor/gems/","") =~ /^(\w+-)?rspec-(\d+)/ && File.exist?("#{subdir}/lib/spec/rake/spectask.rb")
end
rspec_plugin_dir = File.expand_path(File.dirname(__FILE__) + '/../../vendor/plugins/rspec')

if rspec_gem_dir && (test ?d, rspec_plugin_dir)
  raise "\n#{'*'*50}\nYou have rspec installed in both vendor/gems and vendor/plugins\nPlease pick one and dispose of the other.\n#{'*'*50}\n\n"
end

if rspec_gem_dir
  $LOAD_PATH.unshift("#{rspec_gem_dir}/lib") 
elsif File.exist?(rspec_plugin_dir)
  $LOAD_PATH.unshift("#{rspec_plugin_dir}/lib")
end

  require 'spec/rake/spectask'

namespace :spec do


  desc "Run all specs in spec directory and any module specs"
  Spec::Rake::SpecTask.new(:webiva) do |t|
    t.spec_opts = ['--options', "\"#{RAILS_ROOT}/spec/spec.opts\""]
    t.spec_files = FileList['spec/**/*/*_spec.rb'] + FileList['vendor/modules/**/spec/**/*/*_spec.rb']
  end

  desc "Run all specs in spec directory and any module specs with rcov"
  Spec::Rake::SpecTask.new(:webiva_rcov) do |t|
    t.spec_opts = ['--options', "\"#{RAILS_ROOT}/spec/spec.opts\""]
    t.spec_files = FileList['spec/**/*/*_spec.rb'] + FileList['vendor/modules/**/spec/**/*/*_spec.rb']
    t.rcov = true
    t.rcov_opts = lambda do
      IO.readlines("#{RAILS_ROOT}/spec/rcov.opts").map {|l| l.chomp.split " "}.flatten + [ "-i \"vendor/modules/*/app/*\"" ]
    end
  end

  desc "Run all the specs in an individual modules directory"
  Spec::Rake::SpecTask.new(:webiva_module_rcov) do |t|
    module_name =ENV['MODULE'].to_s.underscore
    t.spec_opts = ['--options', "\"#{RAILS_ROOT}/spec/spec.opts\""]
    t.spec_files = FileList["vendor/modules/#{module_name}/spec/**/*_spec.rb"]
    t.rcov = true
    t.rcov_opts = lambda do
      IO.readlines("#{RAILS_ROOT}/spec/rcov.opts").map {|l| l.chomp.split " "}.flatten + [ "-i \"vendor/modules/#{module_name}/lib\" -i \"vendor/modules/#{module_name}/app\"", "--exclude \"app/*,lib/*\"" ]
    end



  end
end
