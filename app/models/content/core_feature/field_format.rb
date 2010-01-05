# Copyright (C) 2009 Pascal Rettig.


class Content::CoreFeature::FieldFormat <  Content::Feature #:nodoc:all

   def self.content_feature_handler_info
    { 
      :name => "Format model field",
      :callbacks => [ :model_generator ], 
      # Available Callbacks
      # :model_generator, - Called when the content model class is being generated
      # :table_actions,  - Add actions to the table TODO
      # :more_table_actions - Add Actions to the more actions dropdown TODO
      # :table_columns,  - Add a new table column to the main table TODO
      # :header_actions, - Add actions to the header of the content model page TODO
      # :add_migration, - Migration to run on the table when this feature is added TODO
      # :remove_migration -Migration to run on the table when this feature is removed TODO
      :options_partial => "/content/core_feature/field_format"
    }
   end
   
   def self.options(val)
    FieldFormatOptions.new(val)
   end
   
   class FieldFormatOptions < HashModel
    attributes :target_field_id => nil, :format_string => ''

     validates_presence_of :target_field_id
   end
   
  

  def model_generator(content_model,cls)
    field = content_model.content_model_fields.detect { |fld| fld.id == options.target_field_id }
    if field
      field_name = field.field

      field_hash = {}
      content_model.content_model_fields.each do |fld|
        field_hash[fld.feature_tag_name.to_sym] = create_field_proc(fld)
      end
      opts = self.options # Need to bind this locally

      cls.send(:before_save) do |entry|
#        begin
          entry.send("#{field_name}=",entry.variable_replace(opts.format_string,field_hash))
#        rescue Exception => e
#          # Die silently
#        end
      end
    end
    
  end

  protected

  def create_field_proc(fld)
    Proc.new { |entry,name| fld.content_display(entry) }
  end
  
end
