module BackgrounDRb; end
  class BackgrounDRb::ServerLogger
    def method_missing(sym, *args, &blk)
      puts "#{sym}: #{args}"
      self
    end  
  end  
require File.dirname(__FILE__) + '/../server/lib/backgroundrb/scheduler.rb'
require File.dirname(__FILE__) + '/../server/lib/backgroundrb/cron_trigger.rb'
require File.dirname(__FILE__) + '/../server/lib/backgroundrb/trigger.rb'
require 'rubygems'
require 'active_support'
require 'test/unit'

class SchedulerTest < Test::Unit::TestCase

  def test_initialize
    scheduler = BackgrounDRb::ScheduleMonitor.new
    assert_equal([], scheduler.jobs)
  end

  class CountExecuted
    attr_reader :executed
    def initialize
      @executed = 0
    end
    def execute
      @executed += 1
    end
  end 

  


  def test_schedule
    #scheduler = BackgrounDRb::ScheduleMonitor.new
    #trigger = BackgrounDRb::CronTrigger.new('1 * * * * * *')
    ##BackgrounDRb::Trigger.new(:start => Time.now,
    ##                                   :end => Time.now+3, 
    ##                                   :repeat_interval => 1)
    #job = CountExecuted.new
    #
    #scheduler.schedule(job, trigger)
    ##scheduler.schedule(job, trigger)
    ##scheduler.schedule proc {puts 'proc1 called!'}, trigger
    #scheduler.run
    #sleep 2.1
    #assert_not_equal(0, job.executed)
    scheduler = BackgrounDRb::ScheduleMonitor.new
    cron = BackgrounDRb::CronTrigger.new('1 * * * * * *')
    job = CountExecuted.new
    job_id = scheduler.schedule(job, cron)
    scheduler.run
    sleep 3.1
    assert_not_equal(3, job.executed)
  end

  def test_unschedule
    scheduler = BackgrounDRb::ScheduleMonitor.new
    simple = BackgrounDRb::Trigger.new(:start => nil,
                                       :end => nil, 
                                       :repeat_interval => 1)
    job = CountExecuted.new

    job_id = scheduler.schedule(job, simple)

    assert_equal(1, scheduler.jobs.size)
    assert_equal(BackgrounDRb::ScheduleMonitor::event.new(job, simple),
      scheduler.unschedule(job_id))
    assert_equal(0, scheduler.jobs.size)
  end

  def test_cleanup
    scheduler = BackgrounDRb::ScheduleMonitor.new
    dead = BackgrounDRb::Trigger.new(:start => nil,
                                     :end => Time.now-2, 
                                     :repeat_interval => 1)
    alive = BackgrounDRb::Trigger.new(:start => nil,
                                      :end => nil, 
                                      :repeat_interval => 1)

    scheduler.schedule(CountExecuted.new, dead)
    scheduler.schedule(CountExecuted.new, alive)

    scheduler.clean_up

    assert_equal(1, scheduler.jobs.size)
    assert_equal(alive, scheduler.jobs.first[:trigger])
  end
  
  # disabled tests - the tests had the wrong expectation, since the
  # trigger is specified to run the first second of a minute, not every
  # second.
=begin
  def test_cron_repeat_fire
    scheduler = BackgrounDRb::ScheduleMonitor.new
    cron = BackgrounDRb::CronTrigger.new('1 * * * * * *')
    job = CountExecuted.new
    job_id = scheduler.schedule(job, cron)
    scheduler.run
    sleep 3.1
    assert_equal(3, job.executed)
  end  
  
  def test_cron_repeat_fire_with_2_seconds
    scheduler = BackgrounDRb::ScheduleMonitor.new
    cron = BackgrounDRb::CronTrigger.new('2 * * * * * *')
    job = CountExecuted.new
    job_id = scheduler.schedule(job, cron)
    scheduler.run
    sleep 4.1
    assert_equal(2, job.executed)
  end
=end
  
  def test_create_cron
    expr = '0 0 0 * *'
    cron = BackgrounDRb::CronTrigger.new(expr)
    assert_equal(expr, cron.cron_expr)
  end

  def test_explicit_no_carry
    input    = Time.local(0, 0, 0, 1, 1, 2004, nil, nil, false, 'UTC')
    cron = BackgrounDRb::CronTrigger.new('10 5 4 3 2')
    expected = Time.local(10, 5, 4, 3, 2, 2004, nil, nil, false, 'UTC')
    assert_equal(expected, cron.fire_time_after(input))
  end

  def test_explicit_no_carry_day
    input    = Time.local(0, 0, 0, 1, 1, 2004, nil, nil, false, 'UTC')
    cron = BackgrounDRb::CronTrigger.new('10 5 4 3 1')
    expected = Time.local(10, 5, 4, 3, 1, 2004, nil, nil, false, 'UTC')
    assert_equal(expected, cron.fire_time_after(input))
  end

  def test_explicit_no_carry_hour
    input    = Time.local(0, 0, 0, 1, 1, 2004, nil, nil, false, 'UTC')
    cron = BackgrounDRb::CronTrigger.new('10 5 4 1 1')
    expected = Time.local(10, 5, 4, 1, 1, 2004, nil, nil, false, 'UTC')
    assert_equal(expected, cron.fire_time_after(input))
  end

  def test_explicit_no_carry_min
    input    = Time.local(0, 0, 0, 1, 1, 2004, nil, nil, false, 'UTC')
    cron = BackgrounDRb::CronTrigger.new('10 5 0 1 1')
    expected = Time.local(10, 5, 0, 1, 1, 2004, nil, nil, false, 'UTC')
    assert_equal(expected, cron.fire_time_after(input))
  end

  def test_explicit_with_carry
    input    = Time.local(0, 1, 23, 1, 1, 2004, nil, nil, false, 'UTC')
    cron = BackgrounDRb::CronTrigger.new('0 0 23 1 1')
    expected = Time.local(0, 0, 23, 1, 1, 2005, nil, nil, false, 'UTC')
    assert_equal(expected, cron.fire_time_after(input))
  end

  def test_implicit_with_carry
    input    = Time.local(0, 1, 23, 1, 1, 2004, nil, nil, false, 'UTC')
    cron = BackgrounDRb::CronTrigger.new('0 0 * * *')
    expected = Time.local(0, 0, 0, 2, 1, 2004, nil, nil, false, 'UTC')
    assert_equal(expected, cron.fire_time_after(input))
  end

  def test_year_before
    input    = Time.local(0, 1, 23, 1, 1, 2004, nil, nil, false, 'UTC')
    cron = BackgrounDRb::CronTrigger.new('0 15 10 * * * 2003')
    expected = nil
    assert_equal(expected, cron.fire_time_after(input))
  end

  def test_year_after
    input    = Time.local(0, 1, 23, 1, 1, 2004, nil, nil, false, 'UTC')
    cron = BackgrounDRb::CronTrigger.new('0 15 10 * * * 2005')
    expected = Time.local(0, 15, 10, 2, 1, 2005, nil, nil, false, 'UTC')
    assert_equal(expected, cron.fire_time_after(input))
  end

  def test_month_over
    input    = Time.local(0, 1, 23, 2, 12, 2004, nil, nil, false, 'UTC')
    cron = BackgrounDRb::CronTrigger.new('0 15 10 1 * * *')
    expected = Time.local(0, 15, 10, 1, 1, 2005, nil, nil, false, 'UTC')
    assert_equal(expected, cron.fire_time_after(input))
  end

  def test_day_over
    input    = Time.local(0, 1, 23, 30, 11, 2004, nil, nil, false, 'UTC')
    cron = BackgrounDRb::CronTrigger.new('* * * 31 * * *')
    expected = Time.local(0, 0, 0, 31, 12, 2004, nil, nil, false, 'UTC')
    assert_equal(expected, cron.fire_time_after(input))
  end

  def test_min_over
    input    = Time.local(2, 59, 12, 30, 11, 2004, nil, nil, false, 'UTC')
    cron = BackgrounDRb::CronTrigger.new('1 * * * * * *')
    expected = Time.local(1, 0, 13, 30, 11, 2004, nil, nil, false, 'UTC')
    assert_equal(expected, cron.fire_time_after(input))
  end

  def test_range
    input0    = Time.local(2, 59, 12, 30, 11, 2004, nil, nil, false, 'UTC')
    cron = BackgrounDRb::CronTrigger.new('28/5,59 1-4,6,20 */1 * 5,0/1 * *')
    assert_equal([28,33,38,43,48,53,58,59], cron.sec)
    assert_equal([1,2,3,4,6,20], cron.min)
    assert_equal((0 .. 23), cron.hour)
    assert_equal((1 .. 12), cron.month)

    expected0 = Time.local(28, 1, 13, 30, 11, 2004, nil, nil, false, 'UTC')
    input1    = Time.local(29, 1, 13, 30, 11, 2004, nil, nil, false, 'UTC')
    expected1 = Time.local(33, 1, 13, 30, 11, 2004, nil, nil, false, 'UTC')
    assert_equal(expected0, cron.fire_time_after(input0))
    assert_equal(expected1, cron.fire_time_after(input1))
  end

end
