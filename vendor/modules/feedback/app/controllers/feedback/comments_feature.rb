# Copyright (C) 2009 Pascal Rettig.

class Feedback::CommentsFeature < ParagraphFeature

  feature :comments_page_comments, :default_feature => <<-FEATURE
      <br/><br/>
      <cms:comments_closed><div class='closed'>Comments are closed</div></cms:comments_closed>
      <cms:add_comment>
        <cms:errors><div class='errors'><cms:value/></div></cms:errors>
        <cms:no_name>Name:<br/><cms:name/><br/></cms:no_name>
        <cms:trans>Add a Comment:</cms:trans><br/>
        <cms:comment/><br/>
        <cms:captcha/>
        <input type='submit' value='Add Comment'/>
        <br/><br/>
      </cms:add_comment>
      <cms:posted_comment><b>Your comment has been posted</b><br/><br/></cms:posted_comment>
      <cms:comments>
        <cms:comment>
          <cms:trackback>
            Trackback from <cms:website_link rel="nofollow" target="_blank"><cms:name/></cms:website_link> at <cms:posted_at /><br/>
            <cms:body/>
          </cms:trackback>
          <cms:no_trackback>
            Posted by <cms:name/> at <cms:posted_at /><br/>
            <cms:body/>
          </cms:no_trackback>
          <cms:not_last><hr/></cms:not_last>
        </cms:comment>
      </cms:comments>
      <cms:no_comments>
        No Comments
      </cms:no_comments>
  FEATURE

  def comments_page_comments_feature(data)
    webiva_feature('comments_page_comments') do |c|
      c.loop_tag('comment') { |t| data[:comments] }
        add_comment_features( c, data )

      c.expansion_tag('logged_in') { |t| myself.id }
      c.expansion_tag('no_name') { |t| myself.missing_name? }
      c.expansion_tag('comments_closed') { |t| data[:comments_closed] }
      
      paragraph_id = data[:paragraph_id] ? data[:paragraph_id] : paragraph.id

      c.ajax_form_for_tag('add_comment',"comment_#{paragraph_id}") do |t|  
        data[:comment] ? 
        { :object => data[:comment] ,
          :page_connection_hash => data[:cached_connection_hash] } : nil
      end
        c.form_error_tag('add_comment:errors')
        c.expansion_tag('user') { |t| myself.id }
        c.field_tag('add_comment:email')
        c.field_tag('add_comment:website')
        c.field_tag('add_comment:name')
        c.field_tag('add_comment:first_name')
        c.field_tag('add_comment:last_name')
        c.field_tag('add_comment:email')
        c.field_tag('add_comment:zip')
        c.field_tag('add_comment:comment',:control => 'text_area', :rows => 6, :cols => 50)
        c.captcha_tag('add_comment:captcha') { |t| data[:captcha] if data[:options].captcha }

      c.expansion_tag('posted_comment') { |t| data[:posted_comment] }
    end
  end

  def add_comment_features(context, data, base='comment')
    context.h_tag(base + ':name') { |t| t.locals.comment.name }
    context.h_tag(base + ':first_name') { |t| t.locals.comment.name.to_s.split(" ")[0] }
    context.value_tag(base + ':body') { |t| t.locals.comment.comment_html.blank? ? simple_format(h(t.locals.comment.comment)) : "<p>#{t.locals.comment.comment_html}</p>" }
    context.date_tag(base + ':posted_at', "%I:%M%p on %B %d %Y".t) { |t| t.locals.comment.posted_at }
    context.link_tag(base + ':website') { |t| t.locals.comment.website }
    context.expansion_tag(base + ':trackback') { |t| t.locals.comment.source_type == 'FeedbackPingback' }
  end

end
