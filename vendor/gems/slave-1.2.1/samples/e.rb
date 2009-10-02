require 'slave'
#
# slaves never outlive their parent.  if the parent exits, even under kill -9,
# the child will die.
#
  slave = Slave.new{ at_exit{ p 'child' };  'the server is this string' }

  Process.kill brutal=9, the_parent_pid=Process.pid
#
# even though parent dies a nasty death the child will still print 'child'
#
