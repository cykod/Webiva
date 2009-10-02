require 'slave'
#
# if certain operations need to take place in the child only a block can be
# used
#
  class Server
    def connect_to_db 
      "we only want to do this in the child process!"
      @connection = :postgresql
    end
    attr :connection
  end

  slave = Slave.new('object' => Server.new){|s| s.connect_to_db}

  server = slave.object

  p server.connection  #=> :postgresql 
#
# errors in the child are detected and raised in the parent
#
  slave = Slave.new('object' => Server.new){|s| s.typo} #=> raises an error!
