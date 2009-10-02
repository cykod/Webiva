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

require 'set'
require 'pp'


module ActiveSalesforce  
  
  class SessionIDAuthenticationFilter
    @@klasses = Set.new
  
  
    def self.register(klass)
      @@klasses.add(klass)
    end
    
    
    def self.filter(controller)
      # Look to see if a SID was passed in the URL
      params = controller.params
      sid = params[:sid]
      
      if sid
        api_server_url = params[:api_server_url]
        
        # Iterate over all classes that have registered for SID auth support
        connection = nil
        @@klasses.each do |klass|
          unless connection
            klass.establish_connection(:adapter => 'activesalesforce', :sid => sid, :url => api_server_url)
            connection = klass.connection
          else
            klass = connection
          end
        end
      end
    end
    
  end

end

