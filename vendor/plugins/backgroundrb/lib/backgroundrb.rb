require 'erb'

module BackgrounDRb
  VERSION = "0.2.1"
end

# The configuration class is shared between server and the DRb clients
# (Rails MiddleMan, console and the MiddleManDRbObject). Defaults set in
# this class is in turn overridden by options from the configuration
# file, which in turn can be overridden by command line options.
class BackgrounDRb::Config
  def self.setup(override_options)

    defaults = {
      :host => "localhost",
      :port => "2000",
      :rails_env => ENV['RAILS_ENV'] || 'development',
      :protocol => 'drbunix',
      :temp_dir => '/tmp'
    }

    begin
      conf_file = \
        override_options[:config] || "#{BACKGROUNDRB_ROOT}/config/backgroundrb.yml"

      raw = YAML.load(ERB.new(IO.read(conf_file)).result)

      # make top level string keys into symbols (compatibility)
      conf_as_sym = {}
      raw.each_key do |key|
        conf_as_sym[key.to_sym] = raw[key]
      end

      options = defaults.merge(conf_as_sym)
    rescue
      options = defaults
    end

    if override_options
      options.merge!(override_options)
    end

    ENV['RAILS_ENV'] ||= options[:rails_env]

    case options[:protocol]
    when 'druby'
      options[:uri] = "druby://" + options[:host] + ":" + options[:port].to_s
    when 'drbunix'
      socket = options[:temp_dir] + "/backgroundrbunix_" + options[:host] + "_" +
        options[:port].to_s
      options[:uri] = "drbunix://" + socket
    when 'drbssl'
      # TODO: need more configuration options
    end

    options
  end
end

# The MiddleManDRbObject is primarily used to establish the MiddleMan
# constant in Rail, but it is also possible to use it to create things
# like DRb connections a remote BackgrounDRb server or another server on
# the same host. At a minimum you need to specify a vaild DRb URI.
class BackgrounDRb::MiddleManDRbObject
  def self.init(options)
    require "drb"
    DRb.start_service('druby://localhost:0')
    middle_man = DRbObject.new(nil, options[:uri])
    middle_man.extend(BackgrounDRb::Cache)
    middle_man
  end
end

# TODO: add Cache documentation
module BackgrounDRb::Cache
  # cache with named key data and time to live( defaults to 10 minutes).
  def cache_as(named_key, ttl=10*60, content=nil)
    if content
      cache(named_key, ttl, Marshal.dump(content))
      content
    elsif block_given?
      res = yield
      cache(named_key, ttl, Marshal.dump(res))
      res
    end  
  end

  def cache_get(named_key, ttl=10*60)
    if self[named_key]
      return Marshal.load(self[named_key])
    elsif block_given?
      res = yield
      cache(named_key, ttl, Marshal.dump(res))
      res
    else
      return nil    
    end     
  end
end

