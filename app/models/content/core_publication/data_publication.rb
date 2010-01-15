# Copyright (C) 2009 Pascal Rettig.

class Content::CorePublication::DataPublication < Content::PublicationType #:nodoc:all
  
  class DataOptions < HashModel
    default_options :content_type => 'text/xml',:entries_displayed => 0
    integer_options :entries_displayed
    validates_presence_of :content_type
  end
  
  options_class DataOptions
  options_partial '/content/core_publication/data_publication_options'
  
  field_types :entry_value, :formatted_value, :dynamic_value
  
  field_options :filter, :order
  
  register_triggers :view
  
  
  def default_feature
    output = "<cms:entries>\n"
    output += "<entries>\n"
    output += "\t<cms:entry>\n"
    output += "\t<entry>\n"
    self.content_publication_fields.each do |fld|

       tag_name = %w(belongs_to document image).include?(fld.content_model_field.field_type) ? fld.content_model_field.field_options['relation_name'] :      fld.content_model_field.field
    
        output += "\t\t<#{tag_name}><cms:#{tag_name}/></#{tag_name}>\n"
    end
    output +="\t</entry>\n"
    output += "\t</cms:entry>\n"
    output += "</entries>\n"
    output += "</cms:entries>\n"
    output  
  end
  
 
  def preview_data
    @publication.get_list_data
  end
      
end
