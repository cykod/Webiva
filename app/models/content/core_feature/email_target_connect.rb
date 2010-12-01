# Copyright (C) 2009 Pascal Rettig.

# The are the built-in features that can be added to a content model
# See Content::Feature for more information
module Content::CoreFeature 

  class EmailTargetConnect <  Content::Feature #:nodoc:all

    def self.content_feature_handler_info
      { 
        :name => 'Connect to Email Targets',
        :callbacks => [ :model_generator, :webform ], 
        # Available Callbacks
        # :model_generator, - Called when the content model class is being generated
        # :table_actions,  - Add actions to the table TODO
        # :more_table_actions - Add Actions to the more actions dropdown TODO
        # :table_columns,  - Add a new table column to the main table TODO
        # :header_actions, - Add actions to the header of the content model page TODO
        # :add_migration, - Migration to run on the table when this feature is added TODO
        # :remove_migration -Migration to run on the table when this feature is removed TODO
        :options_partial => "/content/core_feature/email_target_connect"
      }
    end
    
    def self.options(val)
      EmailTargetConnectOptions.new(val)
    end
    
    class EmailTargetConnectOptions < HashModel
      attributes :add_target_tags => '', :update_target_tags => '',:add_target_source => '', :matched_fields => {}, :override_content_node_user => 'never'

      def validate
        self.errors.add(:matched_fields,'must match email address') unless self.matched_fields.values.include?('end_user.email')
      end    
      
      def matched_fields=(val)
        int_val = {}
        val.each do |key,fld|
          key = key.is_a?(Symbol) ? key : key.to_i
          int_val[key] = fld
        end
        @matched_fields = int_val
      end
    end
    
    

    def model_generator(content_model,cls)
      
      arr = content_model.content_model_fields.map do |elm| 
        options.matched_fields[elm.id].blank? ? nil : [ elm.field, options.matched_fields[elm.id] ]
      end.find_all() { |elm| !elm.blank? }
      
      opts = self.options # Need to bind this locally
      
      cls.send(:define_method,:email_target_connect) do
        { :fields => arr, :add_tags => opts.add_target_tags, :update_tags => opts.update_target_tags, :add_source => opts.add_target_source }
      end
      
      cls.send(:before_save,:email_target_connect_update)
      
      cls.send(:include,Content::CoreFeature::EmailTargetConnect::ContentTypeMethods)
    end
    
    def webform(form, result)
      arr = form.content_model.content_model_fields.map do |elm| 
        options.matched_fields[elm.id].blank? ? nil : [ elm.field, options.matched_fields[elm.id] ]
      end.find_all() { |elm| !elm.blank? }
      
      opts = self.options # Need to bind this locally
      
      update_data = { :fields => arr, :add_tags => opts.add_target_tags, :update_tags => opts.update_target_tags, :add_source => opts.add_target_source }

      target = ContentTypeMethods.email_target_connect_update(update_data, result.data_model)
      result.end_user_id = target.id if target && result.end_user_id.nil?
    end



    module ContentTypeMethods
      def email_target_connect_update
        if update_data = self.email_target_connect
          ContentTypeMethods.email_target_connect_update(update_data, self)
        end  
      end

      def self.email_target_connect_update(update_data, entry)
        connected_fields = update_data[:fields]

        email_field = connected_fields.find() { |fld| fld[1] == 'end_user.email' }
        begin
          email = entry.send(email_field[0])
          
          if email.blank?
            return nil
          end
        rescue Exception => e
          return nil
        end
        
        target = EndUser.find_target(email, :no_create => true)

        address = target.address || EndUserAddress.new()
        
        update_address = false
        connected_fields.each do |field|
          if field[1] == 'data'
            target.options ||= {}
            target.options[field[0].to_sym] = entry.respond_to?("#{field[0]}_display") ? entry.send("#{field[0]}_display") : entry.send(field[0])
          else
            usr_obj,usr_field = field[1].split(".")
            obj = usr_obj == 'end_user' ? target : address
            
            update_address = true if usr_obj == 'address'
            
            # Only update values that we don't have already - don't overwrite our existing data
            obj.send("#{usr_field}=",entry.send(field[0])) if obj.send(usr_field).blank?
          end
        end
        
        if update_address
          address.end_user_id = target.id if address.end_user_id.blank?
          address.save
          target.address_id = address.id
        end
        
        new_object = target.id ? false : true
        
        if new_object && !update_data[:add_source].blank?
          target.lead_source = update_data[:add_source] 
        end 
        
        if target.save
          if !update_data[:add_tags].blank? && new_object
            add_tags = update_data[:add_tags].split(",").collect { |tg| tg.strip }.collect do |tg|
              if tg =~ /^\%\%([a-zA-Z09_\-]+)\%\%$/
                begin
                  entry.send($1)
                rescue Exception => e
                  nil
                end
              else
                tg
              end
            end.find_all { |tg| !tg.blank? }
          
            target.tag_names_add(add_tags.join(","))      
          end
        
          if !update_data[:update_tags].blank?
            update_tags = update_data[:update_tags].split(",").collect { |tg| tg.strip }.collect do |tg|
              if tg =~ /^\%\%([a-zA-Z09_\-]+)\%\%$/
                begin
                  entry.send($1)
                rescue Exception => e
                  nil
                end
              else
                tg
              end
            end.find_all { |tg| !tg.blank? }
          
            target.tag_names_add(update_tags.join(","))
          end 
        
          if update_address && address.end_user_id.blank?
            address.update_attribute(:end_user_id,target.id)
          end

          entry.connected_end_user = target
        end

        target
      end  
    end
  end
end
