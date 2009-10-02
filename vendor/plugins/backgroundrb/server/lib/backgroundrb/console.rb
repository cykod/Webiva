require 'backgroundrb'
require 'irb'
require 'irb/completion'

# TODO: make the middleman methods available to the IRB shell
module IRB # :nodoc:
  def IRB.backgroundrb_console_start(middleman)
    IRB.setup(nil)
    irb = Irb.new(IRB::WorkSpace.new(middleman))
    @CONF[:MAIN_CONTEXT] = irb.context

    trap("SIGINT") do
      irb.signal_handle
    end
    catch(:IRB_EXIT) do
      irb.eval_input
    end
  end
end

# The BackgrounDRb console hooks into IRB to create an IRB WorkSpace
# with a MiddleManDRbObject as context. This give you access to all
# MiddleMan methods without having to qualify them. In the console you
# can therefore do:
#
#   > new_worker(:class => :my_worker, :job_key => :my_key)
#   > worker(:my_key).my_worker_method
#
# As with the Rails console, you can re-load worker classes without
# restarting the server or leaving the console:
#
#   > reload!
#   > loaded_worker_classes
#
class BackgrounDRb::Console
  def self.init(options)
    ARGV.clear
    middleman = BackgrounDRb::MiddleManDRbObject.init(options)
    IRB.backgroundrb_console_start(middleman)
  end
end
