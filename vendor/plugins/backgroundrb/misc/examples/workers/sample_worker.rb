class SampleWorker < BackgrounDRb::Rails
  attr_reader :progress
  
  def do_work(args)
    @progress = 0
    while @progress < 50
      puts @progress
      @progress += 1
      sleep 0.0001
    end  
    done_working!
  end  

end
SampleWorker.register
