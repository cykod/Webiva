class DoWorkWithArgWorker < BackgrounDRb::Worker::Base
  def do_work(args)
    results[:from_do_work] = args
  end
end
DoWorkWithArgWorker.register
