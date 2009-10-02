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

require 'pp'


module ActiveSalesforce  
  module BoxcarCommand
  
    class Base
      attr_reader :verb, :args
      
      def initialize(connection, verb, args)
        @connection = connection
        @verb = verb
        @args = args
      end
      
      def after_execute(result)
      end
    end
    
    
    class Insert < Base
      def initialize(connection, sobject, idproxy)
        super(connection, :create, sobject)
        @idproxy = idproxy
      end
      
      def after_execute(result)
        id = result[:id]
        @idproxy << id if id
      end
    end
    
    
    class Update < Base
      def initialize(connection, sobject)
        super(connection, :update, sobject)
      end
    end
  
  
    class Delete < Base
      def initialize(connection, ids)
        super(connection, :delete, ids)
      end
    end


  end  
end    
