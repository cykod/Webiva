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

require 'thread'  
require 'benchmark'

require 'active_record'
require 'active_record/connection_adapters/abstract_adapter'

require File.dirname(__FILE__) + '/rforce'
require File.dirname(__FILE__) + '/column_definition'
require File.dirname(__FILE__) + '/relationship_definition'
require File.dirname(__FILE__) + '/boxcar_command'
require File.dirname(__FILE__) + '/entity_definition'
require File.dirname(__FILE__) + '/asf_active_record'
require File.dirname(__FILE__) + '/id_resolver'
require File.dirname(__FILE__) + '/sid_authentication_filter'
require File.dirname(__FILE__) + '/recording_binding'
require File.dirname(__FILE__) + '/result_array'
 

module ActiveRecord    
  class Base   
    @@cache = {}
    
    def self.debug(msg)
      logger.debug(msg) if logger
    end
    
    def self.flush_connections()
      @@cache = {}
    end

    # Establishes a connection to the database that's used by all Active Record objects.
    def self.activesalesforce_connection(config) # :nodoc:
      debug("\nUsing ActiveSalesforce connection\n")
      
      # Default to production system using 11.0 API
      url = config[:url]
      url = "https://www.salesforce.com" unless url

      uri = URI.parse(url)
      uri.path = "/services/Soap/u/11.0"
      url = uri.to_s      
      
      sid = config[:sid]
      client_id = config[:client_id]
      username = config[:username].to_s
      password = config[:password].to_s
      
      # Recording/playback support      
      recording_source = config[:recording_source]
      recording = config[:recording]
      
      if recording_source
        recording_source = File.open(recording_source, recording ? "w" : "r")
        binding = ActiveSalesforce::RecordingBinding.new(url, nil, recording != nil, recording_source, logger)
        binding.client_id = client_id if client_id
        binding.login(username, password) unless sid
      end

      # Check to insure that the second to last path component is a 'u' for Partner API
      raise ActiveSalesforce::ASFError.new(logger, "Invalid salesforce server url '#{url}', must be a valid Parter API URL") unless url.match(/\/u\//mi)
      
      if sid
        binding = @@cache["sid=#{sid}"] unless binding
        
        unless binding
          debug("Establishing new connection for [sid='#{sid}']")
          
          binding = RForce::Binding.new(url, sid)
          @@cache["sid=#{sid}"] = binding
          
          debug("Created new connection for [sid='#{sid}']")
        else
          debug("Reused existing connection for [sid='#{sid}']")
        end
      else
        binding = @@cache["#{url}.#{username}.#{password}.#{client_id}"] unless binding
        
        unless binding
          debug("Establishing new connection for ['#{url}', '#{username}, '#{client_id}'")
          
          seconds = Benchmark.realtime {
            binding = RForce::Binding.new(url, sid)
            binding.login(username, password)
            
            @@cache["#{url}.#{username}.#{password}.#{client_id}"] = binding
          }
          
          debug("Created new connection for ['#{url}', '#{username}', '#{client_id}'] in #{seconds} seconds")
        end
      end

      ConnectionAdapters::SalesforceAdapter.new(binding, logger, config)

    end
  end
  
  
  module ConnectionAdapters
    
    class SalesforceAdapter < AbstractAdapter
      include StringHelper
      
      MAX_BOXCAR_SIZE = 200
      
      attr_accessor :batch_size
      attr_reader :entity_def_map, :keyprefix_to_entity_def_map, :config, :class_to_entity_map
      
      def initialize(connection, logger, config)
        super(connection, logger)
        
        @connection_options = nil
        @config = config
        
        @entity_def_map = {}
        @keyprefix_to_entity_def_map = {}
        
        @command_boxcar = []
        @class_to_entity_map = {}
      end
      
      
      def set_class_for_entity(klass, entity_name)
        debug("Setting @class_to_entity_map['#{entity_name.upcase}'] = #{klass} for connection #{self}")
        @class_to_entity_map[entity_name.upcase] = klass
      end
      
      
      def binding
        @connection
      end
      
      
      def adapter_name #:nodoc:
        'ActiveSalesforce'
      end
      
      
      def supports_migrations? #:nodoc:
        false
      end
      
      
      # QUOTING ==================================================
            
      def quote(value, column = nil)
        case value
        when NilClass              then quoted_value = "NULL"
        when TrueClass             then quoted_value = "TRUE"
        when FalseClass            then quoted_value = "FALSE"
        when Float, Fixnum, Bignum then quoted_value = "'#{value.to_s}'"
 	      when Date                  then quoted_value = Time.local(value.year, value.month, value.day).xmlschema
      	when Time                  then quoted_value = value.xmlschema
        else                       quoted_value = super(value, column)
        end      

        quoted_value
      end
      
      # CONNECTION MANAGEMENT ====================================
      
      def active?
        true
      end
      
      
      def reconnect!
        connect
      end
      
      
      # TRANSACTIOn SUPPORT (Boxcarring really because the salesforce.com api does not support transactions)
      
      # Begins the transaction (and turns off auto-committing).
      def begin_db_transaction()    
        log('Opening boxcar', 'begin_db_transaction()')
        @command_boxcar = []
      end
      
      
      def send_commands(commands)
        # Send the boxcar'ed command set
        verb = commands[0].verb
        
        args = []
        commands.each do |command| 
          command.args.each { |arg| args << arg }
        end
        
        response = @connection.send(verb, args)
        
        result = get_result(response, verb)
        
        result = [ result ] unless result.is_a?(Array)
        
        errors = []
        result.each_with_index do |r, n|
          success = r[:success] == "true"
          
          # Give each command a chance to process its own result
          command = commands[n]
          command.after_execute(r)
          
          # Handle the set of failures
          errors << r[:errors] unless r[:success] == "true"
        end
        
        unless errors.empty?
          message = errors.join("\n")
          fault = (errors.map { |error| error[:message] }).join("\n")
          raise ActiveSalesforce::ASFError.new(@logger, message, fault) 
        end
        
        result
      end
      
       
      # Commits the transaction (and turns on auto-committing).
      def commit_db_transaction()   
        log("Committing boxcar with #{@command_boxcar.length} commands", 'commit_db_transaction()')
        
        previous_command = nil
        commands = []
        
        @command_boxcar.each do |command|
          if commands.length >= MAX_BOXCAR_SIZE or (previous_command and (command.verb != previous_command.verb))
            send_commands(commands)
            
            commands = []
            previous_command = nil
          else
            commands << command
	        previous_command = command
          end
        end
        
        # Finish off the partial boxcar
        send_commands(commands) unless commands.empty?
        
      end
      
      # Rolls back the transaction (and turns on auto-committing). Must be
      # done if the transaction block raises an exception or returns false.
      def rollback_db_transaction() 
        log('Rolling back boxcar', 'rollback_db_transaction()')
        @command_boxcar = []
      end
      
      
      # DATABASE STATEMENTS ======================================
      
      def select_all(sql, name = nil) #:nodoc:
        raw_table_name = sql.match(/FROM (\w+)/mi)[1]
          table_name, columns, entity_def = lookup(raw_table_name)
          
          column_names = columns.map { |column| column.api_name }

          # Check for SELECT COUNT(*) FROM query
        
        # Rails 1.1
        selectCountMatch = sql.match(/SELECT\s+COUNT\(\*\)\s+AS\s+count_all\s+FROM/mi)
        
        # Rails 1.0
        selectCountMatch = sql.match(/SELECT\s+COUNT\(\*\)\s+FROM/mi) unless selectCountMatch 
        
        if selectCountMatch
          soql = "SELECT COUNT() FROM#{selectCountMatch.post_match}"
        else 
          if sql.match(/SELECT\s+\*\s+FROM/mi)
            # Always convert SELECT * to select all columns (required for the AR attributes mechanism to work correctly)
            soql = sql.sub(/SELECT .+ FROM/mi, "SELECT #{column_names.join(', ')} FROM")
          else
            soql = sql
          end
        end
        
        soql.sub!(/\s+FROM\s+\w+/mi, " FROM #{entity_def.api_name}")

          if selectCountMatch
            query_result = get_result(@connection.query(:queryString => soql), :query)
            return [{ :count => query_result[:size] }]
          end
          
          # Look for a LIMIT clause
        limit = extract_sql_modifier(soql, "LIMIT")
        limit = MAX_BOXCAR_SIZE unless limit
        
        # Look for an OFFSET clause
        offset = extract_sql_modifier(soql, "OFFSET")
        
        # Fixup column references to use api names
        columns = entity_def.column_name_to_column
        soql.gsub!(/((?:\w+\.)?\w+)(?=\s*(?:=|!=|<|>|<=|>=|like)\s*(?:'[^']*'|NULL|TRUE|FALSE))/mi) do |column_name| 
          # strip away any table alias
          column_name.sub!(/\w+\./, '')
          
          column = columns[column_name]
          raise ActiveSalesforce::ASFError.new(@logger, "Column not found for #{column_name}!") unless column
          
          column.api_name
        end
        
        # Update table name references
        soql.sub!(/#{raw_table_name}\./mi, "#{entity_def.api_name}.")

          @connection.batch_size = @batch_size if @batch_size
          @batch_size = nil
          
          query_result = get_result(@connection.query(:queryString => soql), :query)
          result = ActiveSalesforce::ResultArray.new(query_result[:size].to_i)
          return result unless query_result[:records]

          add_rows(entity_def, query_result, result, limit)
          
          while ((query_result[:done].casecmp("true") != 0) and (result.size < limit or limit == 0))
          # Now queryMore            
          locator = query_result[:queryLocator];
          query_result = get_result(@connection.queryMore(:queryLocator => locator), :queryMore)
          
          add_rows(entity_def, query_result, result, limit)
        end
        
        result
      end
      
      def add_rows(entity_def, query_result, result, limit)
        records = query_result[:records]
        records = [ records ] unless records.is_a?(Array)

        records.each do |record|
          row = {}
          
          record.each do |name, value| 
            if name != :type
              # Ids may be returned in an array with 2 duplicate entries...
              value = value[0] if name == :Id && value.is_a?(Array)
              
              column = entity_def.api_name_to_column[name.to_s]
              attribute_name = column.name
              
              if column.type == :boolean
                row[attribute_name] = (value.casecmp("true") == 0)
              else
                row[attribute_name] = value
              end
            end
          end  
          
          result << row
          
          break if result.size >= limit and limit != 0
        end
      end
      
      def select_one(sql, name = nil) #:nodoc:
        self.batch_size = 1
        
        result = select_all(sql, name)
        
        result.nil? ? nil : result.first
      end
      
      
      def insert(sql, name = nil, pk = nil, id_value = nil, sequence_name = nil)
        log(sql, name) {
          # Convert sql to sobject
          table_name, columns, entity_def = lookup(sql.match(/INSERT\s+INTO\s+(\w+)\s+/mi)[1])
          columns = entity_def.column_name_to_column
          
          # Extract array of column names
          names = sql.match(/\((.+)\)\s+VALUES/mi)[1].scan(/\w+/mi)
          
          # Extract arrays of values
          values = sql.match(/VALUES\s*\((.+)\)/mi)[1]
          values = values.scan(/(NULL|TRUE|FALSE|'(?:(?:[^']|'')*)'),*/mi).flatten
          values.map! { |v| v.first == "'" ? v.slice(1, v.length - 2) : v == "NULL" ? nil : v }
          
          fields = get_fields(columns, names, values, :createable)
          
          sobject = create_sobject(entity_def.api_name, nil, fields)
          
          # Track the id to be able to update it when the create() is actually executed
          id = String.new
          @command_boxcar << ActiveSalesforce::BoxcarCommand::Insert.new(self, sobject, id)
          
          id
        }
      end      
      
      
      def update(sql, name = nil) #:nodoc:
        #log(sql, name) {
          # Convert sql to sobject
          table_name, columns, entity_def = lookup(sql.match(/UPDATE\s+(\w+)\s+/mi)[1])
          columns = entity_def.column_name_to_column
          
          match = sql.match(/SET\s+(.+)\s+WHERE/mi)[1]
          names = match.scan(/(\w+)\s*=\s*(?:'|NULL|TRUE|FALSE)/mi).flatten
          
          values = match.scan(/=\s*(NULL|TRUE|FALSE|'(?:(?:[^']|'')*)'),*/mi).flatten
          values.map! { |v| v.first == "'" ? v.slice(1, v.length - 2) : v == "NULL" ? nil : v }
          
          fields = get_fields(columns, names, values, :updateable)
		      null_fields = get_null_fields(columns, names, values, :updateable)          
          
          id = sql.match(/WHERE\s+id\s*=\s*'(\w+)'/mi)[1]
          
          sobject = create_sobject(entity_def.api_name, id, fields, null_fields)
          
          @command_boxcar << ActiveSalesforce::BoxcarCommand::Update.new(self, sobject)
        #}
      end
      
      
      def delete(sql, name = nil) 
        log(sql, name) {
          # Extract the id
          match = sql.match(/WHERE\s+id\s*=\s*'(\w+)'/mi)
          
          if match 
            ids = [ match[1] ]
          else
            # Check for the form (id IN ('x', 'y'))
            match = sql.match(/WHERE\s+\(\s*id\s+IN\s*\((.+)\)\)/mi)[1]
            ids = match.scan(/\w+/)
          end
          
          ids_element = []        
          ids.each { |id| ids_element << :ids << id }
          
          @command_boxcar << ActiveSalesforce::BoxcarCommand::Delete.new(self, ids_element)
        }
      end
      
      
      def get_updated(object_type, start_date, end_date, name = nil)
        msg = "get_updated(#{object_type}, #{start_date}, #{end_date})"
        log(msg, name) {
          get_updated_element = []
          get_updated_element << 'type { :xmlns => "urn:sobject.partner.soap.sforce.com" }' << object_type
          get_updated_element << :startDate << start_date
          get_updated_element << :endDate << end_date
          
          result = get_result(@connection.getUpdated(get_updated_element), :getUpdated)
          
          result[:ids]
        }
      end
      
      
      def get_deleted(object_type, start_date, end_date, name = nil)
        msg = "get_deleted(#{object_type}, #{start_date}, #{end_date})"
        log(msg, name) {
          get_deleted_element = []
          get_deleted_element << 'type { :xmlns => "urn:sobject.partner.soap.sforce.com" }' << object_type
          get_deleted_element << :startDate << start_date
          get_deleted_element << :endDate << end_date
          
          result = get_result(@connection.getDeleted(get_deleted_element), :getDeleted)
          
          ids = []
          result[:deletedRecords].each do |v| 
            ids << v[:id]
          end
          
          ids
        }      
      end

      
      def get_user_info(name = nil)
        msg = "get_user_info()"
        log(msg, name) {
          get_result(@connection.getUserInfo([]), :getUserInfo)
        }      
      end
      
      
      def retrieve_field_values(object_type, fields, ids, name = nil) 
        msg = "retrieve(#{object_type}, [#{ids.to_a.join(', ')}])"
        log(msg, name) {
          retrieve_element = []      
          retrieve_element << :fieldList << fields.to_a.join(", ")
          retrieve_element << 'type { :xmlns => "urn:sobject.partner.soap.sforce.com" }' << object_type
          ids.to_a.each { |id| retrieve_element << :ids << id }
          
          result = get_result(@connection.retrieve(retrieve_element), :retrieve)
          
          result = [ result ] unless result.is_a?(Array)
          
          # Remove unwanted :type and normalize :Id if required
          field_values = []
          result.each do |v| 
            v = v.dup
            v.delete(:type)
            v[:Id] = v[:Id][0] if v[:Id].is_a? Array
            
            field_values << v
          end
          
          field_values
        }
      end
      
      
      def get_fields(columns, names, values, access_check) 
        fields = {}
        names.each_with_index do | name, n | 
          value = values[n]
          
          if value
            column = columns[name]
            
            raise ActiveSalesforce::ASFError.new(@logger, "Column not found for #{name}!") unless column
            
            value.gsub!(/''/, "'") if value.is_a? String
            
            include_field = ((not value.empty?) and column.send(access_check))
            
            if (include_field)           
              case column.type
                when :date 
                  value = Time.parse(value + "Z").utc.strftime("%Y-%m-%d")
                when :datetime
                  value = Time.parse(value + "Z").utc.strftime("%Y-%m-%dT%H:%M:%SZ")
              end
                          
              fields[column.api_name] = value
            end
          end
        end
        
        fields      
      end
      
	  def get_null_fields(columns, names, values, access_check)
     	fields = {}
 	  	names.each_with_index do | name, n |
 			value = values[n]

 			if !value
 				column = columns[name]
 				fields[column.api_name] = nil if column.send(access_check) && column.api_name.casecmp("ownerid") != 0
 			end
 		end

		fields
	  end
      
      def extract_sql_modifier(soql, modifier)
          value = soql.match(/\s+#{modifier}\s+(\d+)/mi)
          if value            
            value = value[1].to_i
            soql.sub!(/\s+#{modifier}\s+\d+/mi, "")
          end
          
          value
      end
      
      
      def get_result(response, method)
        responseName = (method.to_s + "Response").to_sym
        finalResponse = response[responseName]
        
        raise ActiveSalesforce::ASFError.new(@logger, response[:Fault][:faultstring], response.fault) unless finalResponse
        
        result = finalResponse[:result]
      end       
      
      
      def check_result(result)
        result = [ result ] unless result.is_a?(Array)
        
        result.each do |r|
          raise ActiveSalesforce::ASFError.new(@logger, r[:errors], r[:errors][:message]) unless r[:success] == "true"
        end
        
        result
      end
      
      
      def get_entity_def(entity_name)
        cached_entity_def = @entity_def_map[entity_name]
        
        if cached_entity_def
          # Check for the loss of asf AR setup 
          entity_klass = class_from_entity_name(entity_name)
          
          configure_active_record(cached_entity_def) unless entity_klass.respond_to?(:asf_augmented?)
          
          return cached_entity_def 
        end
        
        cached_columns = []
        cached_relationships = []
        
        begin
          metadata = get_result(@connection.describeSObject(:sObjectType => entity_name), :describeSObject)
          custom = false
        rescue ActiveSalesforce::ASFError
          # Fallback and see if we can find a custom object with this name
          debug("   Unable to find medata for '#{entity_name}', falling back to custom object name #{entity_name + "__c"}")
          
          metadata = get_result(@connection.describeSObject(:sObjectType => entity_name + "__c"), :describeSObject)
          custom = true
        end
        
        metadata[:fields].each do |field| 
          column = SalesforceColumn.new(field) 
          cached_columns << column
          
          cached_relationships << SalesforceRelationship.new(field, column) if field[:type] =~ /reference/mi
        end
        
        relationships = metadata[:childRelationships]
        if relationships
          relationships = [ relationships ] unless relationships.is_a? Array
          
          relationships.each do |relationship|  
            if relationship[:cascadeDelete] == "true"
              r = SalesforceRelationship.new(relationship)
              cached_relationships << r
            end
          end
        end
        
        key_prefix = metadata[:keyPrefix]
        
        entity_def = ActiveSalesforce::EntityDefinition.new(self, entity_name, entity_klass,
                                                            cached_columns, cached_relationships, custom, key_prefix)
        
        @entity_def_map[entity_name] = entity_def
        @keyprefix_to_entity_def_map[key_prefix] = entity_def
        
        configure_active_record(entity_def)
        
        entity_def
      end
      
      
      def configure_active_record(entity_def)
        entity_name = entity_def.name
        klass = class_from_entity_name(entity_name)

        class << klass
          def asf_augmented?
            true
          end
        end
        
        # Add support for SID-based authentication
        ActiveSalesforce::SessionIDAuthenticationFilter.register(klass)
        
        klass.set_inheritance_column nil unless entity_def.custom?
        klass.set_primary_key "id" 
        
        # Create relationships for any reference field
        entity_def.relationships.each do |relationship|
          referenceName = relationship.name
          unless self.respond_to? referenceName.to_sym or relationship.reference_to == "Profile" 
            reference_to = relationship.reference_to
            one_to_many = relationship.one_to_many
            foreign_key = relationship.foreign_key
            
            # DCHASMAN TODO Figure out how to handle polymorphic refs (e.g. Note.parent can refer to 
            # Account, Contact, Opportunity, Contract, Asset, Product2, <CustomObject1> ... <CustomObject(n)>
            if reference_to.is_a? Array
              debug("   Skipping unsupported polymophic one-to-#{one_to_many ? 'many' : 'one' } relationship '#{referenceName}' from #{klass} to [#{relationship.reference_to.join(', ')}] using #{foreign_key}")
              next 
            end
            
            # Handle references to custom objects
            reference_to = reference_to.chomp("__c").capitalize if reference_to.match(/__c$/)
            
            begin
              referenced_klass = class_from_entity_name(reference_to)
            rescue NameError => e
                # Automatically create a least a stub for the referenced entity
                debug("   Creating ActiveRecord stub for the referenced entity '#{reference_to}'")
                
                referenced_klass = klass.class_eval("::#{reference_to} = Class.new(ActiveRecord::Base)")
                
                # Automatically inherit the connection from the referencee
                referenced_klass.connection = klass.connection
            end
            
            if referenced_klass
              if one_to_many
                klass.has_many referenceName.to_sym, :class_name => referenced_klass.name, :foreign_key => foreign_key
              else
                klass.belongs_to referenceName.to_sym, :class_name => referenced_klass.name, :foreign_key => foreign_key
              end
              
              debug("   Created one-to-#{one_to_many ? 'many' : 'one' } relationship '#{referenceName}' from #{klass} to #{referenced_klass} using #{foreign_key}")
            end            
          end
        end
        
      end
      
      
      def columns(table_name, name = nil)
        table_name, columns, entity_def = lookup(table_name)
        entity_def.columns
      end
      
      
      def class_from_entity_name(entity_name)
        entity_klass = @class_to_entity_map[entity_name.upcase]
        debug("Found matching class '#{entity_klass}' for entity '#{entity_name}'") if entity_klass
        
        entity_klass = entity_name.constantize unless entity_klass
        
        entity_klass
      end
      
      
      def create_sobject(entity_name, id, fields, null_fields = [])
        sobj = []
        
        sobj << 'type { :xmlns => "urn:sobject.partner.soap.sforce.com" }' << entity_name
        sobj << 'Id { :xmlns => "urn:sobject.partner.soap.sforce.com" }' << id if id    
        
        # add any changed fields
        fields.each do | name, value |
          sobj << name.to_sym << value if value
        end
        
        # add null fields
        null_fields.each do | name, value |
			sobj << 'fieldsToNull { :xmlns => "urn:sobject.partner.soap.sforce.com" }' << name
		end
        
        [ :sObjects, sobj ]
      end
      
      
      def column_names(table_name)
        columns(table_name).map { |column| column.name }
      end

      
      def lookup(raw_table_name)
        table_name = raw_table_name.singularize
        
        # See if a table name to AR class mapping was registered
        klass = @class_to_entity_map[table_name.upcase]
        
        entity_name = klass ? raw_table_name : table_name.camelize
        entity_def = get_entity_def(entity_name)
        
        [table_name, entity_def.columns, entity_def]
      end
      
      
      def debug(msg)
        @logger.debug(msg) if @logger
      end
      
    end
    
  end
end
