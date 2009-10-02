require 'drb'
require 'logger'
require 'backgroundrb/middleman'

module BackgrounDRb
  module Worker

    class Base
      include DRbUndumped

      attr_reader :jobkey
      attr_accessor :results
      attr_accessor :initial_do_work

      class << self
        def register
          MiddleMan.instance.register_worker_class(self)
        end
      end
      
      def initialize(args=nil, jobkey=nil)
        @jobkey   = jobkey
        @args = args
        @results = {}

        case jobkey
        when :backgroundrb_logger, :backgroundrb_results
        else
          @results.extend(BackgrounDRb::Results)
          @results.init(jobkey)
        end
        @initial_do_work = true
      end

      def logger
        unless self.class == 'BackgrounDRb::Worker::WorkerLogger'
          @logger_stub ||= MiddleMan.instance.worker(:backgroundrb_logger).get_logger
        end
      end

      # Background a method call in a worker
      def work_thread(opts)

        args = opts[:args]
        case 
        when args.is_a?(Symbol)
          case opts[:args].id2name
          when /\A@/
            send_args = self.instance_variable_get(opts[:args].id2name)
          else
            # TODO: not sure what this would be used for
            send_args = args
          end
          send = lambda do
            self.send(opts[:method], send_args)
          end
        when args.nil?
          send = lambda do
            self.send(opts[:method])
          end
        else
          send = lambda do
            self.send(opts[:method], args)
          end
        end

        Thread.new do
          begin
            send.call
          rescue StandardError => e
            logger.error(@jobkey) { "#{ e.message } - (#{ e.class })" } 
            (e.backtrace or []).each do |line|
              logger.error(@jobkey) { "#{line}" }
            end
            self.delete
          end
        end

      end

      def delete
        exit!
      end

    end

    class WorkerResults < Base

      def initialize(args=nil, jobkey=nil)
        @worker_results = {}
        super(args, jobkey)
      end

      def do_work(args)
        logger.info("In ResultsWorker")
      end

      def set_result(job_key, result)
        @worker_results[job_key] ||= Hash.new
        @worker_results[job_key].merge!(result)
      end

      def get_result(job_key, result_key)
        @worker_results[job_key] ||= Hash.new
        if @worker_results[job_key][result_key]
          return @worker_results[job_key][result_key]
        end
      end

      def get_worker_results(job_key)
        @worker_results[job_key] ||= Hash.new
      end

    end

    class WorkerLogger < Base

      def initialize(args=nil, jobkey=nil)
        @@logger ||= Logger.new(BACKGROUNDRB_ROOT + '/log/backgroundrb.log')
        class << @@logger
          def format_message(severity, timestamp, progname, msg)
            "#{timestamp} (#{$$}) #{msg}\n"
          end
        end
        @@logger.info("Starting WorkerLogger")
        super(args, jobkey)
      end

      def get_logger
        @@logger
      end

      def do_work(args)
      end
    end

  end

end  

# RailsBase will be loaded in BackgrounDRb::Server#setup
