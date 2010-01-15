# Copyright (C) 2009 Pascal Rettig.



class Content::CoreFeature::FieldAggregate <  Content::Feature #:nodoc:all

   def self.content_feature_handler_info
    { 
      :name => "Field Aggregate",
      :callbacks => [ :model_generator ], 
      # Available Callbacks
      # :model_generator, - Called when the content model class is being generated
      # :table_actions,  - Add actions to the table TODO
      # :more_table_actions - Add Actions to the more actions dropdown TODO
      # :table_columns,  - Add a new table column to the main table TODO
      # :header_actions, - Add actions to the header of the content model page TODO
      # :add_migration, - Migration to run on the table when this feature is added TODO
      # :remove_migration -Migration to run on the table when this feature is removed TODO
      :options_partial => "/content/core_feature/field_aggregate"
    }
   end
   
   def self.options(val)
    FieldFormatOptions.new(val)
   end
   
   class FieldFormatOptions < HashModel
     attributes :target_field_id => nil, :blank_value => '', :full_value => 'Set', :source_fields => [], :aggregate_type => 'any'
     integer_array_options :source_fields

     validates_presence_of :target_field_id
   end
   
  

  def model_generator(content_model,cls)
    field = content_model.content_model_fields.detect { |fld| fld.id == options.target_field_id }
    if field
      field_name = field.field

      field_list = []
      content_model.content_model_fields.each do |fld|
        if self.options.source_fields.include?(fld.id)
          field_list << fld.field
        end
      end
      opts = self.options # Need to bind this locally

     
      cls.send(:before_save) do |entry|
        begin
          case opts.aggregate_type
          when 'any': is_set  = field_list.reduce(false) { |acc,fld| acc || !entry.send(fld).blank? }
          when 'all':  is_set  = field_list.reduce(true) { |acc,fld| acc && !entry.send(fld).blank? }
          when 'none':  is_set  = field_list.reduce(true) { |acc,fld| acc && entry.send(fld).blank? }
          end
          entry.send("#{field_name}=",is_set ? opts.full_value : opts.blank_value)
        rescue
          Configuration.log_config_error("The Field Aggregate feature in content model %s must be reconfigured" / content_model.name )
        end
      end
    end
    
  end


end
