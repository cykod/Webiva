=begin
  ActiveSalesforce
  Copyright 2006 Doug Chasman
 
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
 
     http://www.apache.org/licenses/LICENSE-2.0
 
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
=end


require 'test/unit'
require 'set'
require 'pp'


module Asf
  module UnitTests

    module RecordedTestCase
      LOGGER = Logger.new(STDOUT)
      @@config = YAML.load_file(File.dirname(__FILE__) + '/config.yml').symbolize_keys
    

      def recording?
        @recording
      end
      
      
      def config
        @@config
      end
      
      
      def initialize(test_method_name)
        super(test_method_name)
        
        @force_recording = Set.new
      end
      
      
      def force_recording(method)
        @force_recording.add(method)
      end


      def unforce_recording(method)
        @force_recording.delete(method)
      end
      
      
      def setup
        @recording = (((not File.exists?(recording_file_name)) or config[:recording]) or @force_recording.include?(method_name.to_sym))
        
        action = { :adapter => 'activesalesforce', :url => config[:url], :username => config[:username], 
          :password => config[:password], :recording_source => recording_file_name }
        
        action[:recording] = true if @recording

        ActiveRecord::Base.logger = LOGGER
        ActiveRecord::Base.clear_active_connections!
        ActiveRecord::Base.reset_column_information_and_inheritable_attributes_for_all_subclasses
        ActiveRecord::Base.establish_connection(action)
        
        @connection = ActiveRecord::Base.connection
      end
      
      
      def recording_file_name
        File.dirname(__FILE__) + "/recorded_results/#{self.class.name.gsub('::', '')}.#{method_name}.recording"
      end
      
    end
    
  end
end