require 'rubygems'
require 'timeout'

module SystemTimer 
 class << self

   def timeout_after(seconds)
     Timeout::timeout(seconds) do
       yield
     end
   end
   
 end
 
end
