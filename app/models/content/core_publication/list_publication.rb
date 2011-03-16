# Copyright (C) 2009 Pascal Rettig.

      
class Content::CorePublication::ListPublication < Content::PublicationType #:nodoc:all


  class ListOptions < HashModel
    default_options :table_class=>nil,:creation_link => nil,:entries_per_page => nil, :fields => []
    integer_options :entries_per_page
  end  
  
  options_class ListOptions
  options_partial '/content/core_publication/list_publication_options'

  feature_name :list
  
  field_types :entry_value #, :formatted_value
  
  field_options :detail_link, :filter, :order
  
  register_triggers :view

  def filter?; true; end
  
  
  def default_feature
    output = "<cms:entries>\n"
    output += "<table>\n<tr>"
    self.content_publication_fields.each do |fld|
      output += "\t<th>#{fld.label}</th>\n"
    end
    output +="</tr>\n"
    output += "<cms:entry>\n"
    output +="\t<tr>\n"
    self.content_publication_fields.each do |fld|

       tag_name = fld.content_model_field.feature_tag_name
    
      case fld.content_model_field_id
      when -1:
	output += "\t\t<td><cms:edit_link><cms:trans>Edit</cms:trans></td>\n"
      when -2:
	output += "\t\t<td><cms:delete_link><cms:trans>Delete</cms:trans></td>\n"
      else 
	      if fld.data[:options] && fld.data[:options].include?('link')
	        output += "\t\t<td><cms:detail_link><cms:#{tag_name}/></cms:detail_link></td>\n"
	      else
	        output += "\t\t<td><cms:#{tag_name}/></td>\n"
	      end
      end
    end
    output +="\t</tr>\n"
    output += "</cms:entry>\n"
    output += "</table>\n"
    output += "<cms:pages/>\n"
    output += "</cms:entries>\n"
    output
  
  end

  def render_html(data,options={})
    # Figure out what type of publication this is
    pages = data[0]
    data = data[1]
    # See if we have a feature
    if !publication.data['table_class'].to_s.empty?
      table_class = "class='#{publication.data['table_class']}'"
    else
      table_class = ''
    end
    output = ''
    detail_page = options[:detail_page]
    current_page = options[:current_page].to_s
    
    if (publication.data['creation_link'] || []).include?('show')
      output += "<div align='right'><a href='#{detail_page}/'>+ Add Entry</a></div>"
    end
    output += "<table #{table_class}><tr>"
    publication.content_publication_fields.each do |fld|
      output += "<th>#{fld.label}</th>"
    end
    output +="</tr>"
    (data || []).each do |entry|
      output +="<tr>"
      publication.content_publication_fields.each do |fld|
        
       if fld.data[:options].include?('link')
  	       output += "<td><a href='#{detail_page}/#{entry.id}'>#{fld.content_display(entry,:excerpt)}</a></td>"
       else
  	       output += "<td>#{fld.content_display(entry,:excerpt)}</td>"
       end
      end
      output +="</tr>"
    end
    output += "</table>"
    if pages[:pages] > 1
      #output += pagination(current_page,pages)
    end
    output
  end
  
  def preview_data
    @publication.get_list_data
  end
    
end


