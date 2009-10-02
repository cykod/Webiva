require 'slave'
#
# if no slave object is given the block itself is used to contruct it 
#
  class Server
    def initialize
      "this is run only in the child"
      @pid = Process.pid
    end
    attr 'pid'
  end

  slave = Slave.new{ Server.new }
  server = slave.object

  p Process.pid
  p server.pid # not going to be the same as parents!
#
# errors are still detected though
#
  slave = Slave.new{ fubar } # raises error in parent
