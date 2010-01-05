# Copyright (C) 2009 Pascal Rettig.


=begin rdoc
This is the base clase for all content model features - these are features that can
be added to custom content models via the "features" tab when configuring a content
model.

To add a handler for a content model feature, add the following to your module's
AdminController:

 register_handler :content, :feature, "ModuleName::FeatureClassName"

The class in question then must define a class method called content_feature_handler_info
that returns a hash with the following information:

    def self.content_feature_handler_info
      { 
        :name => "Human readable feature name",
        :callbacks => [ :model_generator ],  # model_generator is the only supported callback curently
        # Available Callbacks
        # :model_generator, - Called when the content model class is being generated
        # :table_actions,  - Add actions to the table TODO
        # :more_table_actions - Add Actions to the more actions dropdown TODO
        # :table_columns,  - Add a new table column to the main table TODO
        # :header_actions, - Add actions to the header of the content model page TODO
        # :add_migration, - Migration to run on the table when this feature is added TODO
        # :remove_migration -Migration to run on the table when this feature is removed TODO
        :options_partial => "path/to/options/partion"
      }
     end
     
The class must then override the options singleton method which should return a hash model
that is available as a form in the options partial. For example (from app/models/content/core_features/field_format.rb):
  
     def self.options(val)
      FieldFormatOptions.new(val)
     end
     
     class FieldFormatOptions < HashModel
      attributes :target_field_id => nil, :format_string => ''
  
       validates_presence_of :target_field_id
     end
  

This will allow validation to be performed on the options partial

For each supported callback the class must define an instance method. For example the model_generator
callback will be called whenever the content model class is generated. See app/models/content/core_feature/*
for more examples.

   
=end
class Content::Feature

  
  def initialize(content_model_feature)
    @feature = content_model_feature
    @options = content_model_feature.options
  end
  
  attr_reader :feature,:options
  
  def self.options_partial
    self.content_feature_handler_info[:options_partial]
  end

  def self.options(val)
    raise "Must be overridden"
  end

end
