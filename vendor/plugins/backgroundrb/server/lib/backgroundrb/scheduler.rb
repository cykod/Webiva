module BackgrounDRb
  
  class Scheduler
  
    @@event = Struct.new(:job, :trigger, :earliest, :last)
  
    attr_accessor :exit_on_idle
    attr_reader :jobs
  
    def self.event
      @@event  
    end
      
    def initialize(exit_on_idle = true)
      @exit_on_idle = exit_on_idle
      @jobs = Array.new
    end
  
    def schedule(job, trigger = nil)
      job_id = @jobs.size
      @jobs[job_id] = @@event.new(job, trigger, nil)
      job_id
    end
  
    def unschedule(job_id)
      @jobs.delete_at(job_id)
    end

    def clean_up
      now = Time.new
      @jobs.delete_if { |entry| entry.trigger.fire_time_after(now).nil? }
    end
  
    def run
      loop do
        # find the next firing triggers
        todo = next_jobs

        unless todo.empty? 
          todo.each do |entry|
            next  unless @jobs.index(entry)  # make sure since we were sleeping
            begin
              BackgrounDRb::ServerLogger.logger.info('scheduler') {
                "Schedule triggered: #{entry}"
              }
              entry.job.is_a?(Proc) ? entry.job.call : entry.job.execute
            rescue Exception => e
              BackgrounDRb::ServerLogger.log_exception('scheduler', e) 
            end
          end
        end  

        sleep 0.1  # TODO this is dangerous; could skip over some jobs
      end
    end
  
    # find the next wakeup triggers in our job/trigger list
    def next_jobs
      now = Time.now
      earliest = nil
      jobs = Array.new

      @jobs.each do |entry|
        job, trigger = entry.job, entry.trigger
        time = trigger.fire_time_after(now)
        
        case
        when time.nil?
          # do nothing
        when now.to_i == entry.earliest.to_i
          unless entry.last.to_i == now.to_i
            entry.last = now
            jobs << entry
          end
        else
          entry.earliest = time
        end

      end

      jobs
    end
  
  end

  class ScheduleMonitor < Scheduler

    def initialize
      super(false)  # don't exit on idle
      #@threads = []
    end

    def run
      Thread.new {
        super
      }
    end

  end
  
end  

if __FILE__ == $0
  class TestJob # :nodoc:
    attr_reader :executed
    def initialize
      @executed = 0
    end
    def execute
      @executed += 1
      puts "executed #{@executed} times"
    end
  end
  
  require 'middleman'
  include BackgrounDRb
  
  scheduler = ScheduleMonitor.new
  now = Time.now
  simple = Trigger.new(:start => now, :repeat_interval => 1)
  simple2 = Trigger.new(:start => now, :repeat_interval => 3)
  job = TestJob.new
  
  M = BackgrounDRb::MiddleMan.setup(:pool_size => 7)
  prc = proc { puts "called proc1"; M.new_worker :class => :worker }
  prc2 = proc { puts "called proc2"; M.new_worker :class => :worker }
  
   
  scheduler.schedule prc, simple2
  scheduler.schedule prc2, simple
  scheduler.run
  
  cnt = 0
  loop {break if cnt==10;sleep 1.1;cnt+=1}
  
end  
