require 'pathname'
BACKGROUNDRB_ROOT = Pathname.new(RAILS_ROOT).realpath.to_s
require 'backgroundrb'

# Set up a MiddleMan for the BackgrounDRb server configured for this
# particular instance of Rails.
class BackgrounDRb::MiddleManRailsProxy
  def self.init
    config = { :config => "#{BACKGROUNDRB_ROOT}/config/backgroundrb.yml" }
    options = BackgrounDRb::Config.setup(config)
    BackgrounDRb::MiddleManDRbObject.init(options)
  end
end
MiddleMan = BackgrounDRb::MiddleManRailsProxy.init
