require 'slave'
#
# at_exit hanlders are handled correctly in both child and parent 
#
  at_exit{ p 'parent' }
  slave = Slave.new{ at_exit{ p 'child' };  'the server is this string' }
#
# this will print 'child', then 'parent'
#
