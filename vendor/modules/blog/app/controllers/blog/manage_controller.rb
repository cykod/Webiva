# Copyright (C) 2009 Pascal Rettig.

class Blog::ManageController < ModuleController
  
  permit 'blog_writer', :except => [ :configure] 

  permit 'blog_config', :only => [ :configure, :delete ]

  before_filter :check_view_permission, :except => [ :configure, :delete, :display_blog_list_table, :list ]

  component_info 'Blog'
  
  cms_admin_paths 'content', 
                  'Content' => { :controller => '/content' },
                  'Site Blogs' => { :action => 'list' }
  
  # need to include 
   include ActiveTable::Controller   
   active_table :post_table,
                Blog::BlogPost,
                [ hdr(:icon, '', :width=>10),
                  hdr(:string, 'blog_post_revisions.title', :label => 'Post Title'),
                  hdr(:options, 'blog_posts.status', :label => 'Status', :options => Blog::BlogPost.status_select_options ),
                  :published_at,
                  :permalink,
                  :updated_at,
                  hdr(:options, 'blog_posts_categories.blog_category_id', :label => 'Category', :options => :generate_categories, :display => 'select' )
                ]
                
  def self.mail_manager_generator_handler_info
    {
    :name => "Generate From Blog Post",
    :url => { :controller => '/blog/manage',:action => 'generate_mail' }
    }
  end
  
  active_table :generate_post_table,
                Blog::BlogPost,
                [ hdr(:icon, '', :width=>20),
                  hdr(:string, 'blog_blogs.name', :label=> 'Blog'),
                  hdr(:string, 'blog_post_revisions.title', :label => 'Post Title'),
                  :published_at,
                  :updated_at
                ]

  def display_generate_post_table(display=true)
    
      @tbl = generate_post_table_generate params, :order => 'blog_posts.published_at DESC',:joins => [ :active_revision, :blog_blog ]
      
      render :partial =>'generate_post_table' if display
  end
  
  def generate_mail
      display_generate_post_table(false)
      render :partial => 'generate_mail'
  end
  
  def generate_mail_generate
    @post = @blog.blog_posts.find(params[:post_id],:include => :active_revision)

    @align = params[:opts][:align] == 'left' ? 'left' : 'right'
    @padding = params[:opts][:align] == 'left' ? 'padding:0 10px 10px 0;' : 'padding:0 0 10px 0px;'
    @img = "<img class='blog_image' src='#{@post.active_revision.domain_file.url(:small)}' align='#{@align}' style='#{@padding}'>" if params[:opts][:align] != 'none' && @post.active_revision.domain_file
    
    @title = "<h1 class='blog_title'>#{h(@post.active_revision.title)}</h1>"

    @post_content = "<div class='blog_entry'>"
    
    if params[:opts][:header] == 'above'
      @post_content += @title + @img.to_s
    else
      @post_content += @img.to_s + @title
    end
    @post_content += "\n<div class='blog_body'>"
    @post_content += @post.active_revision.body + "</div><div class='blog_clear' style='clear:both;'>&nbsp;</div></div>"
  end
            
                
  def generate_categories
    @blog.blog_categories.collect { |cat| [ cat.name, cat.id ] }
  end

  def post_table(display=true)
      if(request.post? && params[:table_action] && params[:post].is_a?(Hash)) 
      
      case params[:table_action]
      when 'delete':
        params[:post].each do |entry_id,val|
          Blog::BlogPost.destroy(entry_id.to_i)
        end
      when 'publish':
        params[:post].each do |entry_id,val|
          entry = Blog::BlogPost.find(entry_id)
          unless (entry.status == 'published' && entry.published_at && entry.published_at < Time.now) 
              entry.status = 'published'
              entry.published_at = Time.now
              entry.save
          end
        end
      end
    end
    
    @active_table_output = post_table_generate params, :joins => [ :active_revision ], :include => [ :blog_categories ], 
                            :order => 'blog_posts.updated_at DESC', :conditions => ['blog_posts.blog_blog_id = ?',@blog.id ]

    
    render :partial => 'post_table' if display
  end

  def index 
     blog_path(@blog)
  
     post_table(false)
  end
  
  def mail_template
     @entry = @blog.blog_posts.find(params[:path][1],:include => :active_revision) 
     
     
     @mail_template = MailTemplate.create(:name => @blog.name + ":" + @entry.active_revision.title, 
					  :subject => @entry.active_revision.title,
					  :body_html => @entry.active_revision.body,
					  :generate_text_body => true,
					  :body_type => 'html,text')
                                       
    redirect_to :controller => '/mail_manager',:action => 'edit_template', :path => @mail_template.id
  
  end

  def post
     @entry = @blog.blog_posts.find(params[:path][1],:include => :active_revision) if params[:path][1]

      @header = <<-EOF
        <script>
          var cmsEditorOptions = { #{"content_css: '" + url_for(:controller => '/public', :action => 'stylesheet', :path => [ @blog.site_template_id, Locale.language.code ], :editor => 1) + "'," if !@blog.site_template_id.blank? }
                                   #{"body_class: '" + h(@blog.html_class) + "'," if !@blog.html_class.blank?}
                                   dummy: null
                                 }
        </script>
      EOF
      @header += "<script src='/javascripts/cms_form_editor.js' type='text/javascript'></script>"


     if @entry
       @revision = @entry.active_revision.clone
       blog_path(@blog,[ 'Edit Entry: %s', nil, @revision.title ])

       @selected_category_ids = params[:categories] || @entry.category_ids
      
     else
       cms_page_info [ ["Content",url_for(:controller => '/content') ], [ "%s",url_for(:action => 'index', :path => @blog.id),@blog.name], 'Post New Entry' ], "content"
       blog_path(@blog,"Post New Entry")

       @entry = @blog.blog_posts.build()
       @revision = Blog::BlogPostRevision.new()

       @selected_category_ids = params[:categories] || []
     end

     @revision.author = myself.name if @revision.author.blank?

     if request.post? && params[:revision]
        @revision.attributes = params[:revision]
        @entry.attributes = params[:entry]

        @revision.end_user_id = myself.id

        case params[:update_entry][:status]
        when 'draft':
          @entry.make_draft
        when 'publish_now' # if we want to publish the article now
          @entry.publish_now
        when 'post_date'
          @entry.publish(params[:entry_update][:published_at].blank? ? Time.now : (params[:entry_update][:published_at]))
        end
    
        if(@entry.valid? && @revision.valid?)
	    @entry.save
            @entry.save_revision!(@revision)

            @entry.set_categories!(params[:categories])
	    @blog.send_pingbacks(@entry)

            redirect_to :action => 'index', :path => @blog.id 
            return 
        end

     end

     @categories = @blog.blog_categories

  end

  def delete
    @blog = Blog::BlogBlog.find(params[:path][0])
    blog_path(@blog,"Delete Blog")

    if request.post? && params[:destroy] == 'yes'
        @blog.destroy

        redirect_to :controller => '/content', :action => 'index'
    end
  end

  def add_category
      @category = @blog.blog_categories.create(:name => params[:name])

      if @category.id
        render :partial => 'category', :locals => { :category => @category }
      else
        render :inline => '<script>alert("Category already exists");</script>'
      end

  end
  
  def configure
      @blog = Blog::BlogBlog.find(params[:path][0])
      blog_path(@blog,"Configure Blog")
      
      if(request.post? && params[:blog])
        if(@blog.update_attributes(params[:blog])) 
          flash[:notice] = 'Updated Configuration'.t
          redirect_to :action => 'index',:path => @blog.id
        end
      end
    
      @site_templates = [['--Select Site Template--',nil]] + SiteTemplate.find_options(:all,:conditions => 'parent_id IS NULL')
  end
  
  def add_tags
      @existing_tags = params[:existing_tags].to_s
      
      @existing_tag_arr = @existing_tags.split(",").collect { |elem| elem.strip }.find_all { |elem| !elem.blank? }
      @cloud = Blog::BlogPost.tag_cloud()
      
      render :partial => 'add_tags'
  
  end
  
   active_table :blog_list_table,
                Blog::BlogBlog,
                [ :check,
                  hdr(:string,'blog_blogs.name',:label=> 'Blog'),
                  :created_at
                ]
  
  def display_blog_list_table(display=true)
    active_table_action('blog') do |act,bids|
      Blog::BlogBlog.destroy(bids) if act == 'delete'
    end
  
    @tbl = blog_list_table_generate params, :order => 'blog_blogs.created_at DESC', :conditions => ['is_user_blog=1']
    render :partial => 'blog_list_table' if display
  end
  
  def list
    cms_page_path ['Content'], 'Site Blogs'
    display_blog_list_table(false)
  end
  
  protected
  
  def blog_path(blog,path=nil)
    base = ['Content']
    base << 'Site Blogs' if blog.is_user_blog?
    if path
      cms_page_path (base + [[ "%s",url_for(:action => 'index',:path => blog.id),blog.name ]]),path
    else
      cms_page_path base,[ "%s",nil,blog.name ]
    end 
  end


  def check_view_permission
    @blog ||= Blog::BlogBlog.find(params[:path][0])

    if(!myself.has_role?(:blog_config) && @blog.edit_permission?)
      if !myself.has_role?('edit_permission',@blog)
        deny_access!
        return
      end
    end
  end

end
