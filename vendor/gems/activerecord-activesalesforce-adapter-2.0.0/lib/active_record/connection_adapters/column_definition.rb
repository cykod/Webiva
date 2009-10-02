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
require 'active_record/connection_adapters/abstract_adapter'


module ActiveRecord  
  module StringHelper
    def column_nameize(s)
      s.underscore
    end
  end
  
  module ConnectionAdapters
    class SalesforceColumn < Column
      include StringHelper
      
      attr_reader :api_name, :custom, :label, :createable, :updateable, :reference_to
      
      def initialize(field)
        @api_name = field[:name]
        @custom = field[:custom] == "true"
        @name = column_nameize(@api_name)
        @type = get_type(field[:type])
        @limit = field[:length]
        @label = field[:label]
        @name_field = field[:nameField] == "true"
        
        @text = [:string, :text].include? @type
        @number = [:float, :integer].include? @type
        
        @createable = field[:createable] == "true"
        @updateable = field[:updateable] == "true"
        
        if field[:type] =~ /reference/i
          @reference_to = field[:referenceTo]
          @one_to_many = false
          @cascade_delete = false
          
          @name = @name.chop.chop << "id__c" if @custom
        end
      end
      
      def is_name?
        @name_field
      end 
      
      def get_type(field_type)
          case field_type
            when /int/i
              :integer
            when /currency|percent/i
              :float
            when /datetime/i
              :datetime
            when /date/i
              :date
            when /id|string|textarea/i
              :text
            when /phone|fax|email|url/i
              :string
            when /blob|binary/i
              :binary
            when /boolean/i
              :boolean
            when /picklist/i
              :text
            when /reference/i
              :text
          end
      end
      
      def human_name
        @label
      end

    end
    
  end
end    
