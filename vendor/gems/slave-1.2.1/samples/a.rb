require 'slave'
#
# simple usage is simply to stand up a server object as a slave.  you do not
# need to wait for the server, join it, etc.  it will die when the parent
# process dies - even under 'kill -9' conditions
#
  class Server
    def add_two n
      n + 2
    end
  end

  slave = Slave.new :object => Server.new

  server = slave.object
  p server.add_two(40) #=> 42

  slave.shutdown
