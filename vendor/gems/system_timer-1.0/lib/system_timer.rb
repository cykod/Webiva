require 'rubygems'
require 'timeout'

# Timer based on underlying SIGALRM system timers, is a
# solution to Ruby processes which hang beyond the time limit when accessing
# external resources. This is useful when timeout.rb, which relies on green
# threads, does not work consistently.
#
# == Usage
#
#   require 'systemtimer'
#
#   SystemTimer.timeout_after(5) do
#
#     # Something that should be interrupted if it takes too much time...
#     # ... even if blocked on a system call!
#
#   end
#
module SystemTimer 
 class << self
   
   # Executes the method's block. If the block execution terminates before 
   # +seconds+ seconds has passed, it returns true. If not, it terminates 
   # the execution and raises a +Timeout::Error+.
   def timeout_after(seconds)
     install_timer(seconds)
     return yield
   ensure
     cleanup_timer
   end

   # Backward compatibility with timeout.rb
   alias timeout timeout_after 
   
   protected
   
   def install_ruby_sigalrm_handler                 #:nodoc:
     timed_thread = Thread.current  # Ruby signals are always delivered to main thread by default.
     @original_ruby_sigalrm_handler = trap('SIGALRM') do
        log_timeout_received(timed_thread) if SystemTimer.debug_enabled?
        timed_thread.raise Timeout::Error.new("time's up!")
      end
   end
  
   def restore_original_ruby_sigalrm_handler        #:nodoc:
     trap('SIGALRM', original_ruby_sigalrm_handler || 'DEFAULT')
   ensure
     reset_original_ruby_sigalrm_handler
   end
   
   def original_ruby_sigalrm_handler               #:nodoc:
     @original_ruby_sigalrm_handler
   end
 
   def reset_original_ruby_sigalrm_handler         #:nodoc:
     @original_ruby_sigalrm_handler = nil
   end

   def log_timeout_received(timed_thread)          #:nodoc:
     puts <<-EOS
       install_ruby_sigalrm_handler: Got Timeout in #{Thread.current}
           Main thread  : #{Thread.main}
           Timed_thread : #{timed_thread}
           All Threads  : #{Thread.list.inspect}
     EOS
   end
 end

end

require 'system_timer_native'