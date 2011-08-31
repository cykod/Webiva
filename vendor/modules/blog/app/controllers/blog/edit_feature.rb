# Copyright (C) 2009 Pascal Rettig.



class Blog::EditFeature < ParagraphFeature


  feature :blog_edit_list, :default_feature => <<-FEATURE
    <cms:write_link>+ Write a new Post</cms:write_link><br/><br/>
    <cms:post_table style='width:100%'>
      <cms:row>
        <td><cms:checkbox/></td>
        <td><cms:edit_link><cms:title/></cms:edit_link></td>
        <td align='center'><cms:status/></td>
        <td><cms:published_at/></td>
      </cms:row>
    </cms:post_table>
  FEATURE
  

  def blog_edit_list_feature(data)
    webiva_feature(:blog_edit_list) do |c|
      c.link_tag('write') { |t| data[:edit_url] }
      c.end_user_table_tag('post_table','post',:container_id => "cmspara_#{paragraph.id}", :no_pages => data[:mini] ? true : nil,
           :actions => data[:mini] ? nil : [['Delete','delete','Delete the selected posts?']]) { |t| data[:tbl] }
        c.link_tag('post_table:row:edit') { |t| "#{data[:edit_url]}/#{t.locals.post.permalink}" }
        c.value_tag('post_table:row:title') { |t| h t.locals.post.title }
        c.value_tag('post_table:row:status') { |t| "#{t.locals.post.status_display} #{" (Post Dated)".t if t.locals.post.published_at && t.locals.post.published_at > Time.now}" }
        c.datetime_tag('post_table:row:published_at') { |t| t.locals.post.published_at }
    end
  end
  feature :blog_edit_write, :default_feature => <<-FEATURE
    <cms:post>
      <cms:errors>
      <div class='error'>
      There was a problem saving your blog:<br/>
      <cms:value/>
      </div>
      </cms:errors>
      <div class='label'>Post Title:</div>
      <cms:title/>
      <div class='label'>Post Body:</div>
      <cms:body/>
      <div align='right'>
        <cms:published>
          <cms:draft>Revert to Draft</cms:draft><cms:publish>Save</cms:publish>
        </cms:published>
        <cms:not_published>
          <cms:draft>Save as Draft</cms:draft><cms:publish>Save & Publish</cms:publish>
        </cms:not_published>
      </div>
    </cms:post>
  FEATURE
  

  def blog_edit_write_feature(data)
    webiva_feature(:blog_edit_write) do |c|
      c.form_for_tag('post','post',:code => "<input type='hidden' id='post_publish' name='publish_post' value=''/>") { |t| data[:entry ] }
        c.form_error_tag('post:errors')
        c.field_tag('post:title',:size => 50)
        c.field_tag('post:body',:control => 'editor_area', :rows => 20, :cols => 60)        
        c.button_tag('post:publish', :onclick => 'document.getElementById("post_publish").value=1; return true;')
        c.button_tag('post:draft')        
        c.expansion_tag('post:published') { |t| data[:entry].published? }
    end
  end


end

