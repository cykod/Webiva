#!/usr/bin/env ruby

# my take on a easy commit script for rails...
# it is far from prefect, so:
# please feed back the modifications you made to it!
#
# by Cies Breijs -- cies.breijsATgmailDOTcom
# based on a bash script by Anonymous Gentleman
# found here: http://wiki.rubyonrails.org/rails/pages/HowtoUseRailsWithSubversion

to_add = []
to_remove = []
to_checkin = []

`svn status`.each_line do |l|
  action_char, path = l.split(' ', 2)
  path.strip!
  case action_char
    when '?'
      to_add << path
    when '!'
      to_remove << path
    when 'M'
      to_checkin << path
  end
end

puts "\nyou are about to..." 

def print_list(array, str)
  puts "\n#{str}:" 
  array.each { |i| puts "\t"+i }
  puts "\t<nothing>" if array.length == 0
end

print_list(to_add, 'add')
print_list(to_remove, 'remove')
print_list(to_checkin, 'checkin')

puts "\nplease write something for the commit log and hit enter..." 
puts "(hitting enter on an empty line will cancel this commit)\n\n" 

log = gets.strip

if log.empty?
  puts "commit cancelled!\n" 
  exit
end

puts "\ncontacting repository...\n" 

`svn add #{to_add.join(' ')}`
`svn remove #{to_remove.join(' ')}`
puts "\n" + `svn commit -m "#{log.gsub('"', '\"')}"` + "\n" 

puts "running 'svn update' to be shure we are up-to-date..." 
puts `svn update`

puts "\nfinished.\n" 
