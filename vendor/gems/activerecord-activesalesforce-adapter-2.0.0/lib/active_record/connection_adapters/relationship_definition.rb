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


module ActiveRecord  
  module StringHelper
    def column_nameize(s)
      s.underscore
    end
  end
  
  module ConnectionAdapters
 
     class SalesforceRelationship
      include StringHelper
    
      attr_reader :name, :api_name, :custom, :foreign_key, :label, :reference_to, :one_to_many
      
      def initialize(source, column = nil)
        if source[:childSObject]
          relationship = source
          
          if relationship[:relationshipName]
            @api_name = relationship[:relationshipName]
            @one_to_many = true
            @label = @api_name
            @name = column_nameize(@api_name)
            @custom = false
          else 
            @api_name = relationship[:field]
            @one_to_many = relationship[:cascadeDelete] == "true"
            @label = relationship[:childSObject].pluralize
            @custom = relationship[:childSObject].match(/__c$/)

            name = relationship[:childSObject]
            name = name.chop.chop.chop if custom
            
            @name = column_nameize(name.pluralize)
            @name = @name + "__c" if custom
          end
          
          @reference_to = relationship[:childSObject]
          
          @foreign_key = column_nameize(relationship[:field])
          @foreign_key = @foreign_key.chop.chop << "id__c" if @foreign_key.match(/__c$/)
        else
          field = source
          
          @api_name = field[:name]
          @custom = field[:custom] == "true"
          
          @api_name = @api_name.chop.chop unless @custom
          
          @label = field[:label]
          @reference_to = field[:referenceTo]
          @one_to_many = false
          
          @foreign_key = column.name
          @name = column_nameize(@api_name)
        end
      end
    end
    
  end
end    
