#$DEBUG = true
require File.dirname(__FILE__) + '/../spec_helper'

context "BackgrounDRb simple worker" do

  setup do
    @middleman = spec_run_setup
  end

  teardown do
    #spec_run_teardown
  end

  specify "should should return string from method" do
    key = @middleman.new_worker :class => :simple_worker
    worker = @middleman.worker(key)

    worker.simple_work.should == "simple string returned from worker"
    worker.delete
  end

  specify "should set result in method call" do
    key = @middleman.new_worker :class => :simple_worker
    worker = @middleman.worker(key)

    worker.simple_result
    worker.results[:simple].should == "simple result string"
    worker.delete
  end

  specify "should allow for result to be set externally" do
    key = @middleman.new_worker :class => :simple_worker
    worker = @middleman.worker(key)

    # set results from outside the worker
    worker.results[:external] = 9
    worker.results[:external].should == 9

    results_hash = worker.results.to_hash
    results_hash[:external].should == 9
    worker.delete
  end

  specify "should keep results after worker is deleted" do
    key = @middleman.new_worker :class => :simple_worker
    worker = @middleman.worker(key)

    worker.simple_result
    worker.results[:external] = 9
  
    spec_hash = {
      :simple => "simple result string",
      :external => 9
    }

    results_hash = worker.results.to_hash
    results_hash.should == spec_hash
    worker.delete

    # results should still be available after the worker is deleted
    worker.results.to_hash.should == spec_hash
  end

  # When the server was started each time setup was called, every other
  # invocation resulted in an IOError in the WorkerProxy, Moving the
  # server into a singleton class where there is only a single server
  # per context, resolved this issue.
  4.times do
    specify "should work on on subsequent server invocations" do
      key = @middleman.new_worker :class => :simple_worker
      worker = @middleman.worker(key)
      worker.simple_work.should == "simple string returned from worker"
      lambda { worker.delete }.should_not_raise IOError
    end
  end

  specify "should support symbols as names" do
    key = @middleman.new_worker :class => :simple_worker, :job_key => :this_worker
    worker = @middleman.worker(:this_worker)
  end

  # WARNING: leave this here to shut down the server
  specify "context cleanup" do
    SpecBackgrounDRbServer.instance.shutdown
  end

end

context "BackgrounDRb simple worker scheduler" do

  setup do
    @middleman = spec_run_setup
  end

  specify "should schedule with simple trigger" do 

    @middleman.schedule_worker(
      :class => :simple_worker,
      :job_key => :scheduled_worker,
      :worker_method => :simple_work_with_logging,
      :trigger_args => {
        :start => Time.now+1, 
        :end => Time.now+3,
        :repeat_interval => 1
      }
    )

    @middleman.scheduler.jobs.should_not_be_empty
    @middleman.scheduler.clean_up
    @middleman.scheduler.jobs.should_not_be_empty
    sleep 5
    @middleman.scheduler.clean_up
    @middleman.scheduler.jobs.should_be_empty

  end

  specify "should call do_work with args" do

    @middleman.schedule_worker(
      :class => :do_work_with_arg_worker,
      :args => "args for args",
      :job_key => :with_arg_worker,
      :trigger_args => {
        :start => Time.now+1, 
        :end => Time.now+3,
        :repeat_interval => 1
      }
    )
    sleep 2
    results = @middleman.worker(:with_arg_worker).results
    results[:from_do_work].should == "args for args"
    sleep 2
    @middleman.scheduler.clean_up
  end

  specify "should schedule with simple trigger on existing worker" do 
    @middleman.new_worker :class => :simple_worker, 
      :job_key => :scheduled_worker

    @middleman.schedule_worker(:job_key => :scheduled_worker,
      :worker_method => :simple_work_with_logging,
      :trigger_type => :trigger,
      :trigger_args => {:start => Time.now+1, 
        :repeat_interval => 1, :end => Time.now+3})

    @middleman.scheduler.jobs.should_not_be_empty
    @middleman.scheduler.clean_up
    @middleman.scheduler.jobs.should_not_be_empty
    sleep 4
    @middleman.scheduler.clean_up
    @middleman.scheduler.jobs.should_be_empty
  end

  specify "should schedule with MiddleMan#schedule_worker" do
    @middleman.new_worker :class => :simple_worker, 
      :job_key => :scheduled_worker

    @middleman.schedule_worker(:job_key => :scheduled_worker,
      :worker_method => :do_something,
      :worker_method_args => "my argument",
      :trigger_type => :cron_trigger,
      :trigger_args => '0 15 10 * * * *')

    # do something better here, since objects scheduler.jobs contains
    # Proc objects, DRb will fall back to the main DRbObject.
    @middleman.scheduler.jobs.should_not_be_empty
  end

  specify "should create worker if it's not already created" do

    @middleman.schedule_worker(:job_key => :new_worker,
      :class => :simple_worker, :trigger_args => '0 15 10 * * * *' )

  end

  specify "should schedule with :schedule_worker option to #new_worker" do
  end

  # WARNING: leave this here to shut down the server
  specify "context cleanup" do
    SpecBackgrounDRbServer.instance.shutdown
  end
end

context "BackgrounDRb worker logging" do

  setup do
    @middleman = spec_run_setup
  end

  specify "should use method instead of instance variable" do

    key = @middleman.new_worker :class => :simple_worker, 
      :job_key => :yikes
    worker = @middleman.worker(key)
    worker.logger.info "logging something new"

  end

  # WARNING: leave this here to shut down the server
  specify "context cleanup" do
    SpecBackgrounDRbServer.instance.shutdown
  end

end

context "BackgrounDRb worker classes" do

  setup do
    @middleman = spec_run_setup
  end

  specify "should be registered" do

    @middleman.new_worker :class => :simple_worker, 
      :job_key => :yikes
    @middleman.loaded_worker_classes.sort.should == ["DoWorkWithArgWorker","RSSWorker","SimpleWorker"].sort
  end

  # WARNING: leave this here to shut down the server
  specify "context cleanup" do
    SpecBackgrounDRbServer.instance.shutdown
  end

end
