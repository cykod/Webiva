class SimpleWorker < BackgrounDRb::Worker::Base
  def do_work(args)
    logger.info "logging do_work with args: #{args}"
  end

  def simple_work
    "simple string returned from worker"
  end

  def simple_result
    results[:simple] = "simple result string"
  end

  def simple_work_with_logging
    logger.info 'logging something'
    results[:time] = Time.now.to_s
  end

  def simple_method
    self.missing_simple_method
  end

end
SimpleWorker.register
