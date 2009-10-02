require 'rubygems'
require 'daemons'
require 'backgroundrb'
require 'backgroundrb/middleman'
require 'backgroundrb/scheduler'
require 'backgroundrb/console'
require 'optparse'
require 'tmpdir'
require 'fileutils'
require 'drb/acl'

module BackgrounDRb
end

class BackgrounDRb::ServerScheduler
  def self.scheduler
    @@scheduler ||= BackgrounDRb::ScheduleMonitor.new
  end
end

class BackgrounDRb::ServerLogger
  def self.logger

    @@logger ||= ::Logger.new(BACKGROUNDRB_ROOT + '/log/backgroundrb_server.log')
    log_file = @@logger.instance_variable_get('@logdev')

    # Daemons will close open file descriptors.
    if log_file.dev.closed?
      @@logger = ::Logger.new(BACKGROUNDRB_ROOT + '/log/backgroundrb_server.log')
    end

    #class << @@logger
     # def format_message(severity, timestamp, progname, msg)
     #   "#{timestamp.strftime('%Y%m%d-%H:%M:%S')} (#{$$}) #{msg}\n"
     # end
    #end

    @@logger
  end

  def self.log_exception(component, e)
    BackgrounDRb::ServerLogger.logger.error(component) {
      "#{ e.message } - (#{ e.class })"
    }
    (e.backtrace or []).each do |line|
      BackgrounDRb::ServerLogger.logger.error(component) { 
        "#{line}" 
      }
    end
  end
end


class BackgrounDRb::Server


  def config

    Daemons::Controller::COMMANDS << 'console'
    program_args = Daemons::Controller.split_argv(ARGV)
    @cmd = program_args[0]
    backgroundrb_args = program_args[2]

    options = {}

    # defaults
    options[:config] = "#{BACKGROUNDRB_ROOT}/config/backgroundrb.yml"

    @app_option_parser = OptionParser.new do |opts|
      opts.banner = ""
      opts.on("-c", "--config file_path", String, 
          "BackgrounDRb config file (path)") do |config|
        options[:config] = config
      end

      opts.on("-h", "--host name", String, 
          "Server host (default: localhost)") do |host|
        options[:host] = host
      end

      opts.on("-l", "--list", 
          "List configuration options") do 
        options[:list] = true
      end

      opts.on("-p", "--port num", Integer, 
          "Server port (default: 2000)") do |port|
        options[:port] = port
      end

      opts.on("-P", "--protocol string", String, 
          "DRb protocol (default: drbunix)") do |protocol|
        options[:protocol] = protocol
      end

      opts.on("-r", "--rails_env string", String, 
          "Rails environment (default: development)") do |environment|
        options[:rails_env] = environment
      end

      opts.on("-s", "--pool_size num", Integer, 
          "Thread pool size (default: 5)") do |pool_size| 
        options[:pool_size] = pool_size
      end

      opts.on("-t", "--tmp_dir dir_path", String, 
          "Override default temporary directory") do |temp_dir| 
        options[:temp_dir] = temp_dir
      end

      opts.on("-w", "--worker_dir dir_path", String, 
          "Override default worker directory") do |worker_dir|
        options[:worker_dir] = worker_dir
      end
    end
    @app_option_parser.parse!(backgroundrb_args)

    @daemon_options = {
      :dir => BACKGROUNDRB_ROOT + '/log/',
      :dir_mode => :normal,
      :app_optparse => @app_option_parser
    }

    # Get common configuration options, including config file
    options = BackgrounDRb::Config.setup(options)

    # Common server options defaults
    options[:pool_size] ||= 5
    options[:worker_dir] ||= "#{BACKGROUNDRB_ROOT}/lib/workers"
    options[:worker_dir] = File.expand_path(options[:worker_dir])

    # Slave uses Dir::tempdir from stdlib tmdir to store sockets
    options[:temp_dir] ||= '/tmp'
    options[:socket_dir] = options[:temp_dir] + '/backgroundrb.' + $$.to_s

    # Default ACL
    options[:acl] ||= {
      :deny => [
        'all'
      ],
      :allow => [
        'localhost 127.0.0.1'
      ],
      :order => [ 'deny' 'allow' ]
    }

    # Output accumulated configuration 
    if options[:list]
      puts "BackgrounDRb configuration (including cmd line arguments)"
      options.sort_by { |k| k.to_s }.each do |k|
        if k[0] == :acl
          # TODO: format acl
        else
          puts ":" + k[0].to_s + ": " + k[1].to_s
        end
      end
      puts ""
    end

    @backgroundrb_options = options
  end

  def setup

    # Log server configuration
    case @cmd
    when 'start','run','restart'
      BackgrounDRb::ServerLogger.logger.info('server') do
        "Starting BackgrounDRb Server" 
      end
      @backgroundrb_options.each do |key, val|
        BackgrounDRb::ServerLogger.logger.info('server') do 
          key.to_s + ": " + val.to_s 
        end
      end
    end

    case @cmd
    when 'start','run'

      # Remove socket directory if it's already there - risky?
      socket_dir = @backgroundrb_options[:socket_dir]
      if File.directory?(socket_dir)
        FileUtils::rm_rf(socket_dir)
      end

      # We record this process pid as ppid, since Daemon's only will
      # record the a sub process pid, and we need a way to locate and
      # remove the socket directory when the server is stopped.
      ppid_file = @daemon_options[:dir] + '/backgroundrb.ppid'
      File.open(ppid_file, 'w') do |f|
        f.write(Process.pid)
      end

      FileUtils::mkdir_p(socket_dir)

      # DRb Acl
      unless @backgroundrb_options[:protocol] == "drbunix"
        self.setup_drb_acl
      end

    when 'restart'
      puts 'restart not supported, please stop, then start'
      exit 1

    end

    ENV['TMPDIR'] = socket_dir

    # RailsBase uses RAILS_ENV and need to be loaded after the
    # configuration is processed.
    unless BACKGROUNDRB_STANDALONE
      require 'backgroundrb/worker_rails'
    end

  end

  def setup_drb_acl

    acl = []
    acl_config = @backgroundrb_options[:acl]

    [:deny, :allow].each do |acl_type|
      acl_config[acl_type].inject(acl) do |total, part|
        part.gsub!(/,/,' ')
        part.split(/\s+/).each do |sub_part|
          if sub_part.is_a?(String)
            total << "#{acl_type.to_s}"
            total << "#{sub_part}"
          end
        end
      end
    end

    # Will effectively install a DENY_ALLOW if order is not specified
    case acl_config[:order]
    when /\Aallow/
      order = 1 # ALLOW_DENY.
    else
      order = 0 # DENY_ALLOW
    end

    begin
      drb_acl = ACL.new(acl, order)
      DRb.install_acl(drb_acl)
      BackgrounDRb::ServerLogger.logger.info('server') {
        "Installed DRb ACL"
      }
    rescue => e
      BackgrounDRb::ServerLogger.logger.info('server') {
        "Failed to install DRb ACL"
      }
      BackgrounDRb::ServerLogger.log_exception('server', e)
    end
  end

  # Remove socket directory if old ppid information is available
  def cleanup
    begin
      ppid_file = @daemon_options[:dir] + '/backgroundrb.ppid'
      ppid_handle = File.open(ppid_file, 'r')
      ppid = ppid_handle.read

      if @backgroundrb_options[:protocol] == 'drbunix'
        uri = @backgroundrb_options[:uri]
        server_socket = uri.gsub(/drbunix:\/\//,'')
      end

      if ppid
        socket_dir = @backgroundrb_options[:temp_dir] + '/backgroundrb.' + ppid
        if File.directory?(socket_dir)
          FileUtils.rm_rf(socket_dir)
          FileUtils.rm(ppid_file)
        end
        unless server_socket.nil?
          if File.socket?(server_socket)
            FileUtils.rm(server_socket)
          end
        end
      end
    rescue => e
      BackgrounDRb::ServerLogger.log_exception('server', e)
    end
  end

  def run

    # Process configuration and command line arguments into
    # configuration
    self.config

    # Setup server directories and load workers on server start
    self.setup

    case @cmd
    when 'console'
      BackgrounDRb::Console.init(@backgroundrb_options)
      exit 0
    else
      # Run server block
      @server = Daemons.run_proc('backgroundrb', @daemon_options) do 

        # Doesn't seem to work
        at_exit { FileUtils::rm_rf(@backgroundrb_options[:socket_dir]) }

        middleman = BackgrounDRb::MiddleMan.instance.setup(
          :pool_size => @backgroundrb_options[:pool_size],
          :scheduler => BackgrounDRb::ServerScheduler.scheduler,
          :worker_dir => @backgroundrb_options[:worker_dir]
        )

        # Disabled for now - will be configurable
        #$SAFE = 1   # disable eval() and friends
        
        DRb.start_service(@backgroundrb_options[:uri], middleman)
        DRb.thread.join

      end
    end

    # Clean up temporary socket directory
    self.cleanup if @cmd == 'stop'

  end

end

module Daemons # :nodoc:

  # This class in BackgrounDRb overrides the behavior in Daemons in
  # order to kill the process. We expect to replace this with our own
  # daemon/server code at some point, as we don't really need the
  # application group facilities of Daemons.
  class Application # :nodoc:
    def stop
      if options[:force] and not running?
        self.zap
        return
      end

      # This is brute forcing the kill for platforms (Linux) where the
      # daemon process doesn't exit properly with TERM.
      begin
        pid = @pid.pid
        pgid =  Process.getpgid(@pid.pid)
        Process.kill('TERM', pid)
        Process.kill('-TERM', pgid)
        Process.kill('KILL', pid)
      rescue Errno::ESRCH => e
        puts "#{e} #{@pid.pid}"
        puts "deleting pid-file."
      end

      @pid.cleanup rescue nil
    end
  end

  # Override Daemons::Controller to include BackgrounDRb help output
  class Controller # :nodoc:

    def print_usage
      puts "Usage: #{@app_name} <command> <server_options> -- <backgroundrb options>"
      puts 
      puts "Commands: <command>"
      puts ""
      puts "  start         start backgroundrb server"
      puts "  stop          stop backroundrb server"
      puts "  restart       stop and restart backgrondrb server"
      puts "  run           start backgroundrb server and stay on top"
      puts "  zap           set backgroundrb server to stopped state"
      puts 
      puts "Server options: <server_options>:"
      puts @optparse.usage

      if @options[:app_optparse].is_a? OptionParser
        puts "\nBackgrounDRb options (after --)"
        puts @options[:app_optparse].to_s
      end
    end

  end
end
