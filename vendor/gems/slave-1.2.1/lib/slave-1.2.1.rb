require 'drb/drb'
require 'fileutils'
require 'tmpdir'
require 'tempfile'
require 'fcntl'
require 'socket'
require 'sync'

# TODO - lifeline need close-on-exec set in it!

#
# the Slave class encapsulates the work of setting up a drb server in another
# process running on localhost via unix domain sockets.  the slave process is
# attached to it's parent via a LifeLine which is designed such that the slave
# cannot out-live it's parent and become a zombie, even if the parent dies and
# early death, such as by 'kill -9'.  the concept and purpose of the Slave
# class is to be able to setup any server object in another process so easily
# that using a multi-process, drb/ipc, based design is as easy, or easier,
# than a multi-threaded one.  eg
#
#   class Server
#     def add_two n
#       n + 2
#     end
#   end
#  
#   slave = Slave.new 'object' => Server.new
#   server = slave.object
#  
#   p server.add_two(40) #=> 42
#  
# two other methods of providing server objects exist:
#  
# a) server = Server.new "this is called the parent" }
#    Slave.new(:object=>server){|s| puts "#{ s.inspect } passed to block in child process"}
#  
# b) Slave.new{ Server.new "this is called only in the child" }
#  
# of the two 'b' is preferred.
#
  class Slave
#--{{{
    VERSION = '1.2.1'
    def self.version() VERSION end
  #
  # env config
  #
    DEFAULT_SOCKET_CREATION_ATTEMPTS = Integer(ENV['SLAVE_SOCKET_CREATION_ATTEMPTS'] || 42)
    DEFAULT_DEBUG = (ENV['SLAVE_DEBUG'] ? true : false)
    DEFAULT_THREADSAFE = (ENV['SLAVE_THREADSAFE'] ? true : false)
  #
  # class initialization
  #
    @socket_creation_attempts = DEFAULT_SOCKET_CREATION_ATTEMPTS
    @debug = DEFAULT_DEBUG
    @threadsafe = DEFAULT_THREADSAFE
  #
  # class methods
  #
    class << self
#--{{{
      # defineds how many attempts will be made to create a temporary unix domain
      # socket
      attr :socket_creation_attempts, true

      # if this is true and you are running from a terminal information is printed
      # on STDERR
      attr :debug, true

      # if this is true all slave objects will be wrapped such that any call
      # to the object is threadsafe.  if you do not use this you must ensure
      # that your objects are threadsafe __yourself__ as this is required of
      # any object acting as a drb server
      attr :threadsafe, true

      # get a default value 
      def default key
#--{{{
        send key
#--}}}
      end

      def getopts opts
#--{{{
        raise ArgumentError, opts.class unless
          opts.respond_to?('has_key?') and opts.respond_to?('[]')

        lambda do |key, *defval|
          defval = defval.shift
          keys = [key, key.to_s, key.to_s.intern]
          key = keys.detect{|k| opts.has_key? k } and break opts[key]
          defval
        end
#--}}}
      end

      # just fork with out silly warnings
      def fork &b
#--{{{
        v = $VERBOSE
        begin
          $VERBOSE = nil
          Process::fork(&b)
        ensure
        $VERBOSE = v
        end
#--}}}
      end
#--}}}
    end

  #
  # helper classes
  #

  #
  # ThreadSafe is a delegate wrapper class used for implementing gross thread
  # safety around existing objects.  when an object is wrapped with this class
  # as
  #
  #   ts = ThreadSafe.new{ AnyObject.new }
  #
  # then ts can be used exactly as the normal object would have been, only all
  # calls are now thread safe.  this is the mechanism behind the
  # 'threadsafe'/:threadsafe keyword to Slave#initialize
  #
    class ThreadSafe
#--{{{
      instance_methods.each{|m| undef_method m.to_sym unless m[%r/__/]}
      def initialize object
        @object = object
        @sync = Sync.new
      end
      def ex
        @sync.synchronize{ yield }
      end
      def method_missing m, *a, &b
        ex{ @object.send m, *a, &b }
      end
      def respond_to? *a, &b 
        ex{ @object.respond_to? *a, &b }
      end
      def inspect
        ex{ @object.inspect }
      end
      def class
        ex{ @object.class }
      end
#--}}}
    end
  #
  # a simple thread safe hash used to map object_id to a set of file
  # descriptors in the LifeLine class.  see LifeLine::FDS
  #
    class ThreadSafeHash < Hash
      def self.new(*a, &b) ThreadSafe.new(super) end
    end
  #
  # the LifeLine class is used to communitacte between child and parent
  # processes and to prevent child processes from ever becoming zombies or
  # otherwise abandoned by their parents.  the basic concept is that a socket
  # pair is setup between child and parent.  the child process, because it is
  # a Slave, sets up a handler such that, should it's socket ever grow stale,
  # will exit the process.  this class replaces the HeartBeat class from
  # previous Slave versions.
  #
    class LifeLine
#--{{{
      FDS = ThreadSafeHash.new

      def initialize
        @pair = Socket.pair Socket::AF_UNIX, Socket::SOCK_STREAM, 0
        @owner = Process.pid
        @pid = nil
        @socket = nil
        @object_id = object_id

        @fds = @pair.map{|s| s.fileno}
        oid, fds = @object_id, @fds
        FDS[oid] = fds 
        ObjectSpace.define_finalizer(self){ FDS.delete oid } 
      end

      def owner?
        Process.pid == @owner
      end

      def throw *ignored
        raise unless owner?
        @pair[-1].close
        @pair[-1] = nil
        @pid = Process.pid
        @socket = @pair[0]
        @socket.sync = true
      end

      def catch *ignored
        raise if owner?
        @pair[0].close
        @pair[0] = nil
        @pid = Process.pid
        @socket = @pair[-1]
        @socket.sync = true
        close_unused_sockets_after_forking
      end

      def close_unused_sockets_after_forking
        begin
          to_delete = []
          begin
            FDS.each do |oid, fds|
              next if oid == @object_id
              begin
                IO.for_fd(fds.first).close
              rescue Exception => e
                STDERR.puts "#{ e.message } (#{ e.class })\n#{ e.backtrace.join 10.chr }"
              ensure
                to_delete << oid
              end
            end
          ensure
            FDS.ex{ to_delete.each{|oid| FDS.delete oid rescue 42} }
          end
          GC.start
        rescue Exception => e
          42
        end
      end

      def cut
        raise unless owner?
        raise unless @socket
        @socket.close rescue nil
        FDS.delete object_id
      end
      alias_method "release", "cut"

      DELEGATED = %w( puts gets read write close flush each )

      DELEGATED.each do |m|
        code = <<-code
          def #{ m }(*a, &b)
            @socket ? @socket.#{ m }(*a, &b) : raise('no socket!')
          end
        code
        module_eval code, __FILE__, __LINE__
      end

      def on_cut &b
        at_exit{ begin; b.call; ensure; b = nil; end if b}
        Thread.new(Thread.current){|current|
          Thread.current.abort_on_exception = true
          begin
            each{|*a|}
          rescue Exception
            current.raise $!
            42
          ensure
            begin; b.call; ensure; b = nil; end if b
          end
        }
      end

      def cling &b
        on_cut{ begin; b.call if b; ensure; Kernel.exit; end }.join
      end
#--}}}
    end

  #
  # attrs
  #
    attr :obj
    attr :socket_creation_attempts
    attr :debug
    attr :psname
    attr :at_exit
    attr :dumped

    attr :status
    attr :object
    attr :pid
    attr :ppid
    attr :uri
    attr :socket
  #
  # sets up a child process serving any object as a DRb server running locally
  # on unix domain sockets.  the child process has a LifeLine established
  # between it and the parent, making it impossible for the child to outlive
  # the parent (become a zombie).  the object to serve is specfied either
  # directly using the 'object'/:object keyword
  #
  #   Slave.new :object => MyServer.new
  #
  # or, preferably, using the block form
  #
  #   Slave.new{ MyServer.new }
  #
  # when the block form is used the object is contructed in the child process
  # itself.  this is quite advantageous if the child object consumes resources
  # or opens file handles (db connections, etc).  by contructing the object in
  # the child any resources are consumed from the child's address space and
  # things like open file handles will not be carried into subsequent child
  # processes (via standard unix fork semantics).  in the event that a block
  # is specified but the object cannot be constructed and, instead, throws and
  # Exception, that exception will be propogated to the parent process.
  #
  # opts may contain the following keys, as either strings or symbols
  #
  #   object : specify the slave object.  otherwise block value is used.
  #   socket_creation_attempts : specify how many attempts to create a unix domain socket will be made 
  #   debug : turn on some logging to STDERR
  #   psname : specify the name that will appear in 'top' ($0)
  #   at_exit : specify a lambda to be called in the *parent* when the child dies
  #   dumped : specify that the slave object should *not* be DRbUndumped (default is DRbUndumped) 
  #   threadsafe : wrap the slave object with ThreadSafe to implement gross thread safety 
  #
    def initialize opts = {}, &block
#--{{{
      getopt = getopts opts

      @obj = getopt['object']
      @socket_creation_attempts = getopt['socket_creation_attempts'] || default('socket_creation_attempts')
      @debug = getopt['debug'] || default('debug')
      @psname = getopt['psname']
      @at_exit = getopt['at_exit']
      @dumped = getopt['dumped']
      @threadsafe = getopt['threadsafe'] || default('threadsafe')

      raise ArgumentError, 'no slave object or slave object block provided!' if 
        @obj.nil? and block.nil?

      @shutdown = false
      @waiter = @status = nil
      @lifeline = LifeLine.new

      # weird syntax because dot/rdoc chokes on this!?!?
      init_failure = lambda do |e|
        trace{ %Q[#{ e.message } (#{ e.class })\n#{ e.backtrace.join "\n" }] }
        o = Object.new
        class << o
          attr_accessor '__slave_object_failure__'
        end
        o.__slave_object_failure__ = Marshal.dump [e.class, e.message, e.backtrace]
        @object = o
      end

    #
    # child
    #
      unless((@pid = Slave::fork))
        e = nil
        begin
          Kernel.at_exit{ Kernel.exit! }
          @lifeline.catch

          if @obj
            @object = @obj
          else
            begin
              @object = block.call 
            rescue Exception => e
              init_failure[e]
            end
          end

          if block and @obj
            begin
              block[@obj]
            rescue Exception => e
              init_failure[e]
            end
          end

          $0 = (@psname ||= gen_psname(@object))

          unless @dumped or @object.respond_to?('__slave_object_failure__')
            @object.extend DRbUndumped
          end

          if @threadsafe
            @object = ThreadSafe.new @object
          end

          @ppid, @pid = Process::ppid, Process::pid
          @socket = nil
          @uri = nil

          tmpdir, basename = Dir::tmpdir, File::basename(@psname)

          @socket_creation_attempts.times do |attempt|
            se = nil
            begin
              s = File::join(tmpdir, "#{ basename }_#{ attempt }_#{ rand }")
              u = "drbunix://#{ s }"
              DRb::start_service u, @object 
              @socket = s
              @uri = u
              trace{ "child - socket <#{ @socket }>" }
              trace{ "child - uri <#{ @uri }>" }
              break
            rescue Errno::EADDRINUSE => se
              nil
            end
          end

          if @socket and @uri
            trap('SIGUSR2') do
              DBb::thread.kill rescue nil
              FileUtils::rm_f @socket rescue nil
              exit
            end

            @lifeline.puts @socket 
            @lifeline.cling
          else
            @lifeline.release
            warn "slave(#{ $$ }) could not create socket!"
            exit
          end
        rescue Exception => e
          trace{ %Q[#{ e.message } (#{ e.class })\n#{ e.backtrace.join "\n" }] }
        ensure
          status = e.respond_to?('status') ? e.status : 1
          exit(status)
        end
    #
    # parent 
    #
      else
        detach
        @lifeline.throw

        buf = @lifeline.gets
        raise "failed to find slave socket" if buf.nil? or buf.strip.empty?
        @socket = buf.strip
        trace{ "parent - socket <#{ @socket }>" }

        if @at_exit
          @at_exit_thread = @lifeline.on_cut{ 
            @at_exit.respond_to?('call') ? @at_exit.call(self) : send(@at_exit.to_s, self)
          }
        end

        if @socket and File::exist? @socket
          Kernel.at_exit{ FileUtils::rm_f @socket }
          @uri = "drbunix://#{ socket }"
          trace{ "parent - uri <#{ @uri }>" }
        #
        # starting drb on localhost avoids dns lookups!
        #
          DRb::start_service('druby://localhost:0', nil) unless DRb::thread
          @object = DRbObject::new nil, @uri
          if @object.respond_to? '__slave_object_failure__'
            c, m, bt = Marshal.load @object.__slave_object_failure__
            (e = c.new(m)).set_backtrace bt
            trace{ %Q[#{ e.message } (#{ e.class })\n#{ e.backtrace.join "\n" }] }
            raise e 
          end
          @psname ||= gen_psname(@object)
        else
          raise "failed to find slave socket <#{ @socket }>"
        end
      end
#--}}}
    end
  #
  # starts a thread to collect the child status and sets up at_exit handler to
  # prevent zombies.  the at_exit handler is canceled if the thread is able to
  # collect the status
  #
    def detach
#--{{{
      reap = lambda do |cid|
        begin
          @status = Process::waitpid2(cid).last
        rescue Exception => e 
          m, c, b = e.message, e.class, e.backtrace.join("\n")
          warn "#{ m } (#{ c })\n#{ b }"  unless e.is_a? Errno::ECHILD
        end
      end

      Kernel.at_exit do
        shutdown rescue nil
        reap[@pid] rescue nil
      end

      @waiter = 
        Thread.new do
          begin
            @status = Process::waitpid2(@pid).last
          ensure
            reap = lambda{|cid| 'no-op' }
          end
        end
#--}}}
    end
  #
  # wait for slave to finish.  if the keyword 'non_block'=>true is given a
  # thread is returned to do the waiting in an async fashion. eg 
  #
  #   thread = slave.wait(:non_block=>true){|value| "background <#{ value }>"}
  #
    def wait opts = {}, &b
#--{{{
      b ||= lambda{|exit_status|}
      non_block = getopts(opts)['non_block']
      non_block ? Thread.new{ b[ @waiter.value ] } : b[ @waiter.value ]
#--}}}
    end
    alias :wait2 :wait
  #
  # cuts the lifeline and kills the child process - give the key 'quiet' to
  # ignore errors shutting down, including having already shutdown
  #
    def shutdown opts = {}
#--{{{
      quiet = getopts(opts)['quiet']
      raise "already shutdown" if @shutdown unless quiet
      begin; Process::kill 'SIGUSR2', @pid; rescue Exception => e; end
      begin; @lifeline.cut; rescue Exception; end
      raise e if e unless quiet
      @shutdown = true
#--}}}
    end
  #
  # true
  #
    def shutdown?
#--{{{
      @shutdown
#--}}}
    end
  #
  # generate a default name to appear in ps/top
  #
    def gen_psname obj
#--{{{
      "slave_#{ obj.class }_#{ obj.object_id }_#{ Process::ppid }_#{ Process::pid }".downcase.gsub(%r/\s+/,'_')
#--}}}
    end
  #
  # see docs for Slave.default
  #
    def default key
#--{{{
      self.class.default key
#--}}}
    end
  #
  # see docs for Slave.getopts
  #
    def getopts opts 
#--{{{
      self.class.getopts opts 
#--}}}
    end
  #
  # debugging output - ENV['SLAVE_DEBUG']=1 to enable
  #
    def trace
#--{{{
      if @debug 
        STDERR.puts yield
        STDERR.flush
      end
#--}}}
    end

  #
  # a simple convenience method which returns an *object* from another
  # process.  the object returned is the result of the supplied block. eg
  #
  #   object = Slave.object{ processor_intensive_object_built_in_child_process() }
  #
  # eg.
  #
  # the call can be made asynchronous via the 'async'/:async keyword
  #
  #   thread = Slave.object(:async=>true){ long_processor_intensive_object_built_in_child_process() }
  #
  #   # go on about your coding business then, later
  #
  #   object = thread.value 
  #
    def self.object opts = {}, &b
#--{{{
      async = opts.delete('async') || opts.delete(:async) 

      opts['object'] = opts[:object] = lambda(&b)
      opts['dumped'] = opts[:dumped] = true 

      slave = Slave.new opts

      value = lambda do |slave|
        begin
          slave.object.call
        ensure
          slave.shutdown
        end
      end

      async ? Thread.new{ value[slave] } : value[slave] 
#--}}}
    end
#--}}}
  end # class Slave 
