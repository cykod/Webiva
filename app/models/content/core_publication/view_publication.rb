# Copyright (C) 2009 Pascal Rettig.

 class Content::CorePublication::ViewPublication < Content::PublicationType  #:nodoc:all

    class ViewOptions < HashModel
      default_options :title_field => nil, :description_field => nil, :published_at_field => nil, :url_field => nil
    end

    feature_name :display
    
    # add the options class
    options_class ViewOptions
    # set the options partial
    options_partial '/content/core_publication/view_publication_options'
    
    # available fields type - if you use a custom field type,
    # and need validation the you need to define a custom field_options_class below
    field_types :entry_value,  :dynamic_value #, :formatted_value
# Commentted out stuff 
#                :other_value => '/content/core_publication/other_fieldtype_options'
    
#    class ViewFieldOptions < Content::PublicationFieldOptions
#      attributes :something => nil, :yoyo => 'Goober'
#      
#      validates_presence_of :something
#    end
    
#    field_options_class ViewFieldOptions # Defaults to Content::PublicationFieldOptions
    field_options :detail_link, :filter, :order # do |type,fld,f|
#      f.text_field :something
#    end
    
    register_triggers :view    
    
    
   def default_feature
      output = "<cms:entry>\n"
      output += "<table class='styled_table'>\n\n"
      self.content_publication_fields.each do |fld|
         tag_name = fld.content_model_field.feature_tag_name
      
        if fld.field_type == 'value'
            output += "<tr>\n"
            output += "  <td nowrap='1' class='label'>" + fld.label  + "</td>\n"
            output += "  <td nowrap='1' class='data'><cms:#{tag_name}/></td>\n"
            output += "</tr>\n"
        end
      end 
      output += "<tr>\n"
      output += "  <td colspan='2' align='right'><cms:return_link>Return</cms:return_link></td>\n"
      output += "</tr>\n"
      output += "</table>\n"
      output += '</cms:entry>'
      
      output
    end 
    
    
  # Helper function that renders a publication view
  def render_html(data,options = {})
    if publication.publication_type == 'view'
      result = '<table>'
      publication.content_publication_fields.each do |fld|
	      if fld.field_type == 'value'
	        result += "<tr><td valign='baseline'>#{fld.label}:</td><td valign='baseline'>#{fld.content_display(data,:form)}</td></tr>"
	      end
      end
      result += "</table>"
      if !options[:return_page].to_s.strip.blank?
        result +=" <a href='#{options[:return_page]}'>#{'Return'.t}</a><br/>"
      end
      result
    else
      'Invalid Publication View'
    end
  end
  
  def preview_data
    cls = @publication.content_model.content_model
    cls.find(:first) || cls.new
  end  
         
end 
  
