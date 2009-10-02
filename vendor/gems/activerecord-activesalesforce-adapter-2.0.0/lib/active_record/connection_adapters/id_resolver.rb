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
  class IdResolver
    attr_reader :object_type_to_ids
    
    def initialize(connection)
      @connection = connection
      @object_type_to_ids = {}
    end
    
    
    def add(record, columns = nil)
      if columns
        columns = columns.to_a.map { |column_name| record.column_for_attribute(column_name) }
      else
        columns = record.class.columns
      end
      
      columns.each do |column|
        reference_to = column.reference_to
        next unless reference_to
        
        value = record.send(column.name)
        if value
          ids = @object_type_to_ids[reference_to] ||= Set.new
          ids << value
        end
      end
    end
    
    
    def resolve
      result = {}
      
      @object_type_to_ids.each do |object_type, ids|
        entity_def = @connection.get_entity_def(object_type)
        
        fields = (entity_def.columns.reject { |column| not column.is_name? }).map { |column| column.api_name }
        
        # DCHASMAN TODO Boxcar into requests of no more than 200 retrieves per request
        puts "Resolving references to #{object_type}"
        field_values = @connection.retrieve_field_values(object_type, fields, ids.to_a, "#{self}.resolve()") 
        
        field_values.each do |field_value|
          id = field_value.delete(:Id)
          result[id] = field_value
        end
      end
      
      result
    end
    
    
    def serialize
      YAML.dump @object_type_to_ids
    end


    def deserialize(source)
      @object_type_to_ids = YAML.load(source)
    end
    
  end
  
end    
