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

module ActiveSalesforce
  
  module ActiveRecord
    
    module Mixin
      def self.append_features(base) #:nodoc:
        super
        
        base.class_eval do  
          class << self
            def set_table_name(value = nil, &block)
              super(value, &block)
              
              connection.set_class_for_entity(self, table_name.singularize)
            end        
          end
        end
      end
    end
  
  end

end
