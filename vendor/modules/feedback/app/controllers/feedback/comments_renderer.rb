# Copyright (C) 2009 Pascal Rettig.

class Feedback::CommentsRenderer < ParagraphRenderer

  paragraph :comments

   feature :comments, :default_feature => <<-FEATURE
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

  def comments_feature(data)
    webiva_feature('comments') do |c|
      c.define_tag 'posted' do |tag|
        flash[:comment_posted] ? tag.expand : ''
      end

      c.define_tag 'no_comments' do |tag|
        data[:comments].length == 0 ? tag.expand : nil 
      end
      c.define_tag 'comments' do |tag|
        data[:comments].length == 0 ? nil : tag.expand
      end

      c.define_tag 'comment' do |tag|
          result = ''
        data[:comments].each_with_index do |comment,index|
          tag.locals.comment = comment
          tag.locals.index = index+1
          tag.locals.first = comment == data[:comments].first
          tag.locals.last = comment == data[:comments].last
          result << tag.expand
        end

        result
      end

      c.define_tag('comment:name') { |tag| h(tag.locals.comment.name) }
      c.define_tag('comment:first_name') { |tag| h(tag.locals.comment.name.to_s.split(" ")[0]) }
      c.define_tag('comment:body') { |tag| simple_format(h(tag.locals.comment.comment)) }
      c.define_tag('comment:posted_at') do |tag| 
        tag.locals.comment.posted_at.localize(tag.attr['format'] || "%I:%M%p on %B %d %Y".t)
      end

      c.define_tag('logged_in') { |tag| myself.id ? tag.expand : '' }
      c.define_tag('not_logged_in') { |tag| myself.id ? '' : tag.expand }
      
      c.form_for_tag('add_comment',"comment_#{paragraph.id}") { |t|  data[:comment] }
          c.form_error_tag('add_comment:errors')
          c.field_tag('add_comment:name')
          c.field_tag('add_comment:comment',:control => 'text_area', :rows => 6, :cols => 50)
          c.captcha_tag('add_comment:captcha') 
          
      c.define_tag 'add_comment:name_field' do |tag|
         "<input type='text' class='name_field' size='#{tag.attr['size'] || 40}' name='comment_#{paragraph.id}[name]' />"
      end

      c.define_tag 'add_comment:comment_field' do |tag|
        "<textarea class='comment_field' name='comment_#{paragraph.id}[comment]' cols='#{tag.attr['cols'] || 50}' rows='#{tag.attr['rows'] || 6}'/></textarea>"
      end

      c.define_tag 'posted_comment' do |tag|
        data[:posted_comment] ? tag.expand : nil
      end
   end
  end

  def comments

    options = paragraph_options(:comments)
    @comment = Comment.new

    if !editor?
    
      if options.linked_to_type == 'page'
        content_link = [ paragraph.page_revision.revision_container_type,paragraph.page_revision.revision_container_id ]
      else
        connection_type,content_link = page_connection()
      end
      
      return(render_paragraph :inline => '') unless content_link

      content_target_string = "#{content_link[0]}#{content_link[1]}"
      display_string =  "#{paragraph.id}#{myself.user_class_id}"


      param_str = 'comment_' + paragraph.id.to_s
      if request.post? && params[param_str]
        if myself.id || options.allowed_to_post == 'all'
          @comment = Comment.new(:target_type => content_link[0], :target_id => content_link[1],
                        :posted_at => Time.now, :posted_ip => request.remote_ip,
                        :comment => params[param_str][:comment],
                        :name => myself.id ? myself.name : params[param_str][:name],
                        :end_user_id => myself.id)
          @comment.captcha_invalid = true if options.captcha && !simple_captcha_valid?
          if @comment.save
            target_cls = content_link[0].constantize
            if(target_cls && target_cls.respond_to?("comment_posted"))
                target_cls.comment_posted(content_link[1])
            end
    
    
            if !editor? && paragraph.update_action_count > 0
              atr = @comment.attributes.slice('name','posted_ip','posted_at','comment')
              atr['target'] = @comment.target.title if @comment.target && @comment.target.respond_to?(:title)
              paragraph.run_triggered_actions(atr,'action',myself)
            end

            # Clear Cache for any comments
            DataCache.expire_content("Comments",content_target_string)
    
            # Make sure we know if we posted after redirect
            flash[:posted_comment] = true if @comment.id
    
            redirect_paragraph :page
            return
          end
        end
      end
  
      return(render_paragraph :inline => "Please Configure Paragraph".t) unless content_link
    else
      # Only get the cached output if we haven't posted
      feature_output = nil # DataCache.get_content("Comments",content_target_string,display_string) if !request.post? && !options.captcha 
    end

    if editor? || !feature_output

      if editor?
        comments = Comment.find(:all,:order => options.order.to_s == 'newest' ? 'posted_at DESC' : 'posted_at',:conditions => ['rating >= ?',options.show ], :limit => 10)
      else
        comments = Comment.find(:all,:order => options.order.to_s == 'newest' ? 'posted_at DESC' : 'posted_at',:conditions => ['target_type = ? AND target_id =? AND rating >= ?',content_link[0],content_link[1],options.show ])
      end

      data = {:comments => comments, :posted_comment => flash[:posted_comment], :comment => @comment }

      feature_output = comments_feature(data)
      
      # Only save the cached output if we haven't posted
      DataCache.put_content("Comments",content_target_string,display_string,feature_output) if !request.post? && !options.captcha  && !editor?
    end
    
    render_paragraph :text => feature_output

  end
end
