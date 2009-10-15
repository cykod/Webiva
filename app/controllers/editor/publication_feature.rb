# Copyright (C) 2009 Pascal Rettig.



class Editor::PublicationFeature < ParagraphFeature


  feature :form
  feature :list
  feature :display
  feature :data
  
  include ActionView::Helpers::FormTagHelper
  
  def form_feature(publication,data)

    pub_options = publication.data || {}
    size = pub_options[:field_size] || nil;

    webiva_feature(publication.feature_name) do |c|
#      c.form_for_tag("form")
      c.define_tag "form" do |tag|
        multipart = data[:multipart] ? 'multipart/form-data' : nil
        form_tag('',:method => 'post', :enctype => multipart) + tag.expand + "</form>"
      end
      
      c.define_tag 'edit_butt' do |tag|
        "<input type='submit' value='#{tag.single? ? 'Edit'.t : tag.expand}'/>"
      end
      
      publication.content_publication_fields.each do |fld|
        tag_name = %w(belongs_to document image).include?(fld.content_model_field.field_type) ? fld.content_model_field.field_options['relation_name'] :      fld.content_model_field.field
        
        if fld.field_type=='input'
          c.define_tag "form:#{tag_name}" do |tag|
            opts = { :label => fld.label,:size => size, :control => fld.data[:control] }
            opts[:size] = tag.attr['size'] if tag.attr['size']
            fld.form_field(data[:form],opts.merge(tag.attr))
          end
          
          c.value_tag "form:#{tag_name}_error" do |tag|
            data[:form].output_error_message(fld.label,fld.content_model_field.field)
          end
        elsif fld.field_type == 'value'
          c.value_tag("entry:#{tag_name}") { |tag| fld.content_model_field.content_display(data[:entry],:full,tag.attr) }
        end
      end
    end
  end
  
  


def display_feature(publication,data)

   pub_options = publication.data || {}

   webiva_feature(publication.feature_name) do |c|
      c.expansion_tag('entry') { |tag|  tag.locals.entry = data[:entry]  }

      c.define_tag "next" do |tag|
       if data[:offset]
        data[:max] = data[:publication].get_filtered_count(data[:filter_options]) unless data[:max]
        if data[:offset] < data[:max]
          tag.locals.offset = data[:offset] + 1
          tag.single? ? tag.locals.offset : tag.expand
        else
          nil
        end
       else
        nil
       end
      end

      c.define_tag "previous" do |tag|
        if data[:offset] && data[:offset] > 1
          tag.locals.offset = data[:offset] - 1
          tag.single? ? tag.locals.offset : tag.expand
        else
          nil
        end
      end

      c.define_tag("next:offset") { |tag| tag.locals.offset }
      c.link_tag("next:") { |tag| data[:page_href] + "/" + tag.locals.offset.to_s }

      c.define_tag("previous:offset") { |tag| tag.locals.offset }
      c.link_tag("previous:") { |tag| data[:page_href] + "/" + tag.locals.offset.to_s }

      publication.content_publication_fields.each do |fld|
        tag_name = %w(belongs_to document image).include?(fld.content_model_field.field_type) ? fld.content_model_field.field_options['relation_name'] :      fld.content_model_field.field
        if fld.field_type=='value'
          
          if %w(document image).include?(fld.content_model_field.field_type)
            c.define_tag "entry:#{tag_name}_url" do |tag|
              file = tag.locals.entry.send(fld.content_model_field.field_options['relation_name'])
              file.url(tag.attr['size'] || nil)
            end
          end
          
          if fld.content_model_field.field_type == 'image'
            c.define_image_tag("entry:#{tag_name}",'entry',fld.content_model_field.field_options['relation_name'])
          else 
            c.value_tag("entry:#{tag_name}") do |tag|
              fld.content_model_field.content_display(data[:entry],:size,tag.attr)
            end
          end
        end
      end

      c.link_tag("return") { |tag| data[:return_page] }
   end
 end
    

 def data_feature(publication,data)
   webiva_feature(publication.feature_name) do |c|
     c.define_loop_tag('entry','entries') { data[:entries] }

     publication.content_publication_fields.each do |fld|
       fld.content_model_field.site_feature_value_tags(c,'entry',:full)
     end
   end
 end
  

 def list_feature(publication,data)
   webiva_feature(publication.feature_name,data) do |c|
     c.loop_tag('entry','entries') { |tag| data[:entries].is_a?(Array) && data[:entries]   }
     c.value_tag('entry:id') { |tag| tag.locals.entry.id }
     c.link_tag('entry:list') { |tag| Configuration.domain_link(paragraph_page_url) }
     c.link_tag('entry:detail') { |tag| "#{data[:detail_page]}/#{tag.locals.entry.id}" }
     
     publication.content_publication_fields.each do |fld|
       case fld.content_model_field_id
       when -1:
           c.define_tag "entry:edit_button" do |tag|
           "<form action='#{data[:detail_page]}/#{tag.locals.entry.id}' method='get'><input type='submit' value='#{tag.expand}'/></form>"
         end
       when -2:
           c.define_tag "entry:delete_button" do |tag|
           "<form onsubmit='return confirm(\"#{jh "Are you sure you want to delete this entry?".t}\");' action='#{data[:detail_page]}/#{tag.locals.entry.id}' method='get'><input type='submit' value='#{tag.expand}'/></form>"
         end
       else
         fld.content_model_field.site_feature_value_tags(c,'entry',:full)
       end
    end
    c.pagelist_tag('pages') { |t| data[:pages] }
   end
  end

end
