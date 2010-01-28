# vim: syntax=Ruby
require 'rubygems'
require 'rake/rdoctask'
require 'rake/testtask'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "memcache-client"
    s.summary = s.description = "A Ruby library for accessing memcached."
    s.email = "mperham@gmail.com"
    s.homepage = "http://github.com/mperham/memcache-client"
    s.authors = ['Eric Hodel', 'Robert Cottrell', 'Mike Perham']
    s.has_rdoc = true
    s.files = FileList["[A-Z]*", "{lib,test}/**/*", 'performance.txt']
    s.test_files = FileList["test/test_*.rb"]
    s.rubyforge_project = 'seattlerb'
  end

rescue LoadError
  puts "Jeweler not available. Install it for jeweler-related tasks with: sudo gem install jeweler"
end


Rake::RDocTask.new do |rd|
	rd.main = "README.rdoc"
	rd.rdoc_files.include("README.rdoc", "FAQ.rdoc", "History.rdoc", "lib/memcache.rb")
	rd.rdoc_dir = 'doc'
end

Rake::TestTask.new do |t|
  t.warning = true
end

task :default => :test

task :rcov do
  `rcov -Ilib test/*.rb`
end
