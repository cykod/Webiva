# Copyright (C) 2009 Pascal Rettig.

# Put your code that runs your task inside the do_work method it will be
# run automatically in a thread. You have access to all of your rails
# models.  You also get logger and results method inside of this class
# by default.
class OtherWorker <  BackgrounDRb::Rails
  
  # Args: file_path
  # 
  def do_work(args)
  
    #ActiveRecord::Base.cms_setup
    logger.warn("In Do Work:")
    #logger.warn Process.pid.to_s
    #logger.warn("\n\n")
    
    @processed = true
  end
  
  def finished?
    @processed == true
  end
  

end
OtherWorker.register
