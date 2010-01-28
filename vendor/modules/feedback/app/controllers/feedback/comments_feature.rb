# Copyright (C) 2009 Pascal Rettig.

class Feedback::CommentsFeature < ParagraphFeature

  feature :comments_page_comments, :default_feature => <<-FEATURE
      <br/><br/>
      <cms:add_comment>
        <cms:errors><div class='errors'><cms:value/></div></cms:errors>
        <cms:not_logged_in>Name:<br/><cms:name/><br/></cms:not_logged_in>
        <cms:trans>Add a Comment:</cms:trans><br/>
        <cms:comment/><br/>
        <cms:captcha/>
        <input type='submit' value='Add Comment'/>
        <br/><br/>
      </cms:add_comment>
      <cms:posted_comment><b>Your comment has been posted</b><br/><br/></cms:posted_comment>
      <cms:comments>
        <cms:comment>
        Posted by <cms:name/> at <cms:posted_at /><br/>
        <cms:body/>
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
      
      paragraph_id = data[:paragraph_id] ? data[:paragraph_id] : paragraph.id

      c.form_for_tag('add_comment',"comment_#{paragraph_id}") { |t|  data[:comment] }
        c.form_error_tag('add_comment:errors')
        c.field_tag('add_comment:email')
        c.field_tag('add_comment:website')
        c.field_tag('add_comment:name')
        c.field_tag('add_comment:comment',:control => 'text_area', :rows => 6, :cols => 50)

        if data[:options] &&  data[:options].captcha
	  c.captcha_tag('add_comment:captcha')
	else
	  c.define_tag('add_comment:captcha') { |t| '' }
	end

      c.expansion_tag('posted_comment') { |t| data[:posted_comment] }
    end
  end

  def add_comment_features(context, data, base='comment')
    context.h_tag(base + ':name') { |t| t.locals.comment.name }
    context.h_tag(base + ':first_name') { |t| t.locals.comment.name.to_s.split(" ")[0] }
    context.value_tag(base + ':body') { |t| t.locals.comment.comment_html.blank? ? simple_format(h(t.locals.comment.comment)) : "<p>#{t.locals.comment.comment_html}</p>" }
    context.date_tag(base + ':posted_at', "%I:%M%p on %B %d %Y".t) { |t| t.locals.comment.posted_at }
  end

end
