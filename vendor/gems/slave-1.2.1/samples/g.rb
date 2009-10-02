require 'slave'
#
# Slave.object can used when you want to construct an object in another
# process.  in otherwords you want to fork a process and retrieve a single
# returned object from that process as opposed to setting up a server.
#
  this = Process.pid
  that = Slave.object{ Process.pid }

  p 'this' => this, 'that' => that

#
# any object can be returned and it can be returned asychronously via a thread
#
  thread = Slave.object(:async => true){ sleep 2 and [ Process.pid, Time.now ] }
  this = [ Process.pid, Time.now ]
  that = thread.value 
  
  p 'this' => this, 'that' => that
