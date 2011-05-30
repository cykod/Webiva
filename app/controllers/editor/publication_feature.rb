# Copyright (C) 2009 Pascal Rettig.



class Editor::PublicationFeature < ParagraphFeature #:nodoc:all


  feature :form
  feature :list
  feature :display
  feature :data
  
  include ActionView::Helpers::FormTagHelper
  
  def form_feature(publication,data)

    pub_options = publication.data || {}
    size = pub_options[:field_size] || nil;

    webiva_custom_feature(publication.feature_name,data) do |c|
      c.form_for_tag("form","entry_#{publication.id}",:html => { :enctype => data[:multipart] ? 'multipart/form-data' : nil } )  do |tag|
        data[:submitted] ? nil : data[:entry]
      end

      if publication.publication_type == 'edit'
        c.define_button_tag('form:delete',:name => "entry_#{publication.id}[delete]", :value => 'Delete')
      end

      c.expansion_tag('submitted') { |t|  data[:submitted] }
      c.value_tag('submitted:success_text') { |t| data[:options].success_text}

      c.define_tag 'edit_butt' do |tag|
        button_label = tag.single? ?  (pub_options[:button_label].blank?  ? 'Edit' : pub_options[:button_label] ) : tag.expand
        "<input type='submit' value='#{vh button_label}'/>"
      end
      c.define_tag 'create_butt' do |tag|
        button_label = tag.single? ?  (pub_options[:button_label].blank?  ? 'Create' : pub_options[:button_label] ) : tag.expand
        "<input type='submit' value='#{vh button_label}'/>"
      end
      c.publication_field_tags('form',publication)
    end
  end
  
  


def display_feature(publication,data)

   pub_options = publication.data || {}

   webiva_custom_feature(publication.feature_name) do |c|
      c.expansion_tag('entry') { |tag|  tag.locals.entry = data[:entry]  }

      c.value_tag('entry:id') { |tag| tag.locals.entry.id }

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

      c.define_publication_field_tags("entry",publication,:local => :entry)

      c.link_tag("return") { |tag| data[:return_page] }
   end
 end
    

 def data_feature(publication,data)
   webiva_custom_feature(publication.feature_name) do |c|
     c.define_loop_tag('entry','entries') { data[:entries] }

     publication.content_publication_fields.each do |fld|
       fld.content_model_field.site_feature_value_tags(c,'entry',:full)
     end
   end
 end
  

 def list_feature(publication,data)
   webiva_custom_feature(publication.feature_name,data) do |c|
     c.loop_tag('entry','entries') { |tag| data[:entries].is_a?(Array) && data[:entries]   }
     c.value_tag('entry:id') { |tag| tag.locals.entry.id }
     c.link_tag('entry:list') { |tag| Configuration.domain_link(paragraph_page_url) }
     c.link_tag('entry:detail') { |tag| "#{data[:detail_page]}/#{tag.locals.entry.id}" }
     c.value_tag('entry:score') { |t| t.locals.entry.content_score }
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
     

     c.publication_filter_form_tags("filter","filter_#{paragraph.id}", publication) { |t| [ data[:filter], data[:searching]] }
     
    c.pagelist_tag('pages') { |t| data[:pages] }
   end
  end

end
