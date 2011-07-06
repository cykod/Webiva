# Copyright (C) 2009 Pascal Rettig.



class Blog::EditRenderer < ParagraphRenderer

  features '/blog/edit_feature'

  paragraph :list, :ajax => true
  paragraph :write

  include EndUserTable::Controller
  
  

  def list
    @options = paragraph_options(:list)
    
    conn_type,conn_id = page_connection(:input)

    target_conn_type,target_conn_id = page_connection(:target_url)
    if !target_conn_id.blank?
      @target_connection_url = "/#{target_conn_id}"
    end

    if editor?
      @blog = Blog::BlogBlog.find(:first,:conditions => "is_user_blog = 1")
    else
      @target = conn_id
      @blog = Blog::BlogBlog.find_by_target_type_and_target_id(@target.class.to_s,@target.id) if @target
    end

    if !@blog && @options.auto_create && @target
      @blog = Blog::BlogBlog.create_user_blog(sprintf(@options.blog_name,@target.name),@target)
    end
    
    return render_paragraph(:text => '') if !@blog
 
    @tbl = end_user_table( :post_list,
                             Blog::BlogPost,
                             [ 
                              EndUserTable.column(:blank),
                              EndUserTable.column(:string,'blog_post_revisions.title',:label => 'Post Title'),
                              EndUserTable.column(:string,'blog_posts.status',:label => 'Status',:options => Blog::BlogPost.status_select_options ),
                              EndUserTable.column(:string,'blog_posts.published_at',:label => 'Published At',:datetime => true )
                             ]
                          )
                             
    end_user_table_action(@tbl) do |act,pids|
     @blog.blog_posts.find(pids).each { |post|  post.destroy } if act == 'delete'
    end

    end_user_table_generate(@tbl,:conditions => [ "blog_blog_id = ?",@blog.id],:order => 'blog_posts.updated_at DESC',:per_page => 20, :include => :active_revision)
  
    edit_url = @options.edit_page_url.to_s + @target_connection_url.to_s
    data = { :tbl => @tbl, :edit_url => edit_url }
    
    render_paragraph :text => blog_edit_list_feature(data)
  end
  
  
  def write
    @options = paragraph_options(:write)

    conn_type,conn_id = page_connection(:target)

    return render_paragraph(:text => '')  if !conn_type

    target_conn_type,target_conn_id = page_connection(:target_url)
    if !target_conn_id.blank?
      @target_connection_url = "/#{target_conn_id}"
    end

    if editor?
      @blog = Blog::BlogBlog.find(:first,:conditions => "is_user_blog = 1")
      @target = @blog.target if @blog
    else
      @target = conn_id
      @blog = Blog::BlogBlog.find_by_target_type_and_target_id(@target.class.to_s,@target.id)
    end

    if !@blog && @options.auto_create && @target
      @blog = Blog::BlogBlog.create_user_blog(sprintf(@options.blog_name,@target.name),@target)
    end

    return render_paragraph(:text => '') if !@blog || !@target

    post_conn_type,post_conn_id = page_connection(:post)

    if post_conn_type == :post_permalink
      @entry = @blog.blog_posts.find_by_permalink(post_conn_id,:include => :active_revision) || @blog.blog_posts.build
    elsif editor?
      @entry= @blog.blog_post.find(:first)
    end

    require_js('tiny_mce/tiny_mce.js')
    require_js('front_cms_form_editor')

      if request.post? && params[:post]

        @published = @entry.published? 
        @entry.attributes = params[:post].slice(:title,:body)
        @entry.permalink = ''
        @entry.end_user_id = myself.id 

        if params[:publish_post].to_i == 1
          @entry.publish_now
        else
          @entry.make_draft
        end

      if @entry.valid?
        @entry.generate_preview 
        @entry.save
        if @entry.published? &&  !@published 
          @handlers = get_handler_info(:blog,:targeted_after_publish)
          @handlers.each do |hndl|
            hndl[:class].send(:after_publish,@entry,myself)
          end

        end
        list_url = @options.list_page_url + @target_connection_url.to_s
        return redirect_paragraph list_url
      end      
    end

    data = { :post => @revision, :entry => @entry, :revision => @revision }
    render_paragraph :text => blog_edit_write_feature(data)
  end


end
