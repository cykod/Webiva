#!/usr/bin/env ruby
# TODO: rewrite as a real script with status and all that jazz
path = File.expand_path(File.dirname(__FILE__))

unless ENV['PATH'].split(File::PATH_SEPARATOR).any? { |p| File.exist?("#{p}/starling") }
  puts "starling not found in your PATH. Add /var/lib/gems/1.8/bin to your PATH"
  exit 1
end

def start_background(path)
 `#{path}/starling.rb`
 `#{path}/workling_client start`
end


def end_background(path) 
  `#{path}/kill_starling.rb`
 `#{path}/workling_client stop`
end


if ARGV[0] == 'start'
 start_background(path)
elsif ARGV[0] == 'stop'
 end_background(path)
elsif ARGV[0] == 'restart'
 end_background(path)
 start_background(path)
else
 puts('Usage: ./script/background.rb [stop|start|restart]')
 puts('Will respect RAILS_ENV environment variable')
end



