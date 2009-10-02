module BackgrounDRb
  module Worker
    class RailsBase < Base
      include DRbUndumped
      require BACKGROUNDRB_ROOT + '/config/boot.rb'
      require 'active_record'
      require 'active_support'

      def initialize(args=nil, jobkey=nil)
#         BACKGROUNDRB_ROOT.untaint
#         db_config_data = IO.read("#{BACKGROUNDRB_ROOT}/config/database.yml")
#         db_config_data.untaint
#         erb = ERB.new(db_config_data)
#         erb.untaint
#         result = erb.result
#         db_config = YAML.load(result)
# 
#         rails_environment = ENV['RAILS_ENV']

#        ActiveRecord::Base.allow_concurrency = true
        #ActiveRecord::Base.establish_connection(
        #  db_config[rails_environment]
        #)
        require BACKGROUNDRB_ROOT + '/config/environment.rb'
        super(args, jobkey)
      end

    end
  end

  # compatibility class
  class Rails < Worker::RailsBase; end 
end
