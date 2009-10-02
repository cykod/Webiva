class RailsWorker < BackgrounDRb::Worker::RailsBase
  def do_work
    sleep 10000   
  end

  def progress
    "this is worker2 progress"
    ActiveRecord.methods
  end
end
