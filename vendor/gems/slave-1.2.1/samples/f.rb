require 'slave'
#
# slaves created previously are visible to newly created slaves - in this
# example the child process of slave_a communicates directly with the child
# process of slave_a 
#
  slave_a = Slave.new{ Array.new }
  slave_b = Slave.new{ slave_a.object }

  a, b = slave_b.object, slave_a.object

  b << 42
  puts a #=> 42
