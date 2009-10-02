
class ProgressWorker < BackgrounDRb::Rails

  attr_accessor :text
  
  def do_work(args)
    results[:progress] = 0
    @text = args[:text]
      while results[:progress] < 100
        sleep rand / 2
        a = [1,3,5,7]
        results[:progress] += a[rand(a.length-1)]
        if results[:progress] >= 100
          results[:progress] = 100
          @text = @text.upcase + " : object_id:" + self.object_id.to_s
        end
      end
  end

  def progress
    results[:progress]
  end
end

ProgressWorker.register
