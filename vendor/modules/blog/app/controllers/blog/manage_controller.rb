# Copyright (C) 2009 Pascal Rettig.

class Blog::ManageController < ModuleController
  
  permit 'blog_writer', :except => [ :configure] 

  permit 'blog_config', :only => [ :configure, :delete, :import ]

  before_filter :check_view_permission, :except => [ :configure, :delete, :display_blog_list_table, :list, :generate_mail, :generate_mail_generate, :display_generate_post_table, :import ]

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
    @post = Blog::BlogPost.find(params[:post_id])

    @align = params[:opts][:align] == 'left' ? 'left' : 'right'
    @padding = params[:opts][:align] == 'left' ? 'padding:0 10px 10px 0;' : 'padding:0 0 10px 0px;'
    @img = "<img class='blog_image' src='#{@post.domain_file.url(:small)}' align='#{@align}' style='#{@padding}'>" if params[:opts][:align] != 'none' && @post.domain_file
    
    @title = "<h1 class='blog_title'>#{h(@post.title)}</h1>"

    @post_content = "<div class='blog_entry'>"
    
    if params[:opts][:header] == 'above'
      @post_content += @title + @img.to_s
    else
      @post_content += @img.to_s + @title
    end
    @post_content += "\n<div class='blog_body'>"
    @post_content += @post.body_content + "</div><div class='blog_clear' style='clear:both;'>&nbsp;</div></div>"
  end
            
                
  def generate_categories
    @blog.blog_categories.collect { |cat| [ cat.name, cat.id ] }
  end

  def post_table(display=true)

    active_table_action(:post) do |act,eids| 
      entries = Blog::BlogPost.find(eids)
      case act
      when 'delete': entries.map(&:destroy)
      when 'publish': entries.map(&:publish!)
      when 'unpublish': entries.map(&:unpublish!)
      when 'duplicate': entries.map(&:duplicate!)
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
     @entry = @blog.blog_posts.find(params[:path][1])
     
     
     @mail_template = MailTemplate.create(:name => @blog.name + ":" + @entry.title, 
					  :subject => @entry.title,
					  :body_html => @entry.body,
					  :generate_text_body => true,
					  :body_type => 'html,text')
                                       
    redirect_to :controller => '/mail_manager',:action => 'edit_template', :path => @mail_template.id
  
  end

  def post
     @entry = @blog.blog_posts.find(params[:path][1]) if params[:path][1]

      @header = <<-EOF
        <script>
          var cmsEditorOptions = { #{"content_css: '" + url_for(:controller => '/public', :action => 'stylesheet', :path => [ @blog.site_template_id, Locale.language.code ], :editor => 1) + "'," if !@blog.site_template_id.blank? }
                                   #{"body_class: '" + h(@blog.html_class) + "'," if !@blog.html_class.blank?}
                                   dummy: null
                                 }
        </script>
      EOF
      require_js('cms_form_editor')

     if @entry
       blog_path(@blog,[ 'Edit Entry: %s', nil, @entry.title ])
     else
       blog_path(@blog,"Post New Entry")
       @entry = @blog.blog_posts.build()
     end
     @selected_category_ids = params[:categories] || @entry.category_ids

     @entry.author = myself.name if @entry.author.blank?

     if request.post? && params[:entry]
        @entry.attributes = params[:entry]

        case params[:update_entry][:status]
        when 'draft':       @entry.make_draft
        when 'publish_now': @entry.publish_now
        when 'preview':     @entry.make_preview
        when 'post_date'
          @entry.publish(params[:entry][:published_at].blank? ? Time.now : (params[:entry][:published_at]))
        end
    
        if @entry.save
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

  def import
    @blog = Blog::BlogBlog.find(params[:path][0])
    blog_path(@blog,"Import Blog")

    @import = ImportOptions.new params[:import]
    @import.wordpress_import_settings = ['comments', 'pages'] unless params[:import]

    if request.post? && @import.valid?
      if params[:commit]
        if @import.import @blog, myself
          redirect_to :action => 'index', :path => [ @blog.id ]
        end
      else
        redirect_to :action => 'index', :path => [ @blog.id ]
      end
    end
  end

  protected
  
  class ImportOptions < HashModel
    attributes :import_file_id => nil, :wordpress_export_file_id => nil, :wordpress_url => nil, :wordpress_username => nil, :wordpress_password => nil, :wordpress_import_settings => [], :rss_url => nil

    domain_file_options :import_file_id, :wordpress_export_file_id

    def validate
      if self.import_file_id.blank? && self.wordpress_export_file_id.blank? && self.wordpress_url.blank? && self.rss_url.blank?
        self.errors.add_to_base 'Import settings not specified'
      elsif ! self.rss_url.blank?
        self.errors.add(:rss_url, 'is invalid') unless URI::regexp(%w(http https)).match(self.rss_url)
      elsif self.import_file_id.blank? && self.wordpress_export_file_id.blank? && ! self.wordpress_url.blank?
        self.errors.add(:wordpress_url, 'is invalid') unless URI::regexp(%w(http https)).match(self.wordpress_url)
        self.errors.add(:wordpress_username, 'is missing') if self.wordpress_username.blank?
        self.errors.add(:wordpress_password, 'is missing') if self.wordpress_password.blank?
      end
    end

    def wordpress_importer
      return @wordpress_importer if @wordpress_importer
      @wordpress_importer = Blog::WordpressImporter.new
      @wordpress_importer.import_comments = self.wordpress_import_settings.include?('comment')
      @wordpress_importer.import_pages = self.wordpress_import_settings.include?('pages')
      @wordpress_importer
    end

    def rss_importer
      @rss_importer ||= Blog::RssImporter.new
    end

    def import(blog, user)
      if self.import_file
        blog.import_file(self.import_file, user)
      elsif ! self.rss_url.blank?
        self.rss_importer.blog = blog
        if self.rss_importer.import_feed(self.rss_url) 
          self.errors.add(:rss_url, 'failed to import feed') unless self.rss_importer.import
        else
          self.errors.add(:rss_url, 'is invalid')
        end
      elsif self.wordpress_export_file
        self.wordpress_importer.blog = blog
        self.wordpress_importer.import_file(self.wordpress_export_file)
        self.errors.add(:wordpress_export_file_id, self.wordpress_importer.error) unless self.wordpress_importer.import
      elsif ! self.wordpress_url.blank?
        self.wordpress_importer.blog = blog
        unless self.wordpress_importer.import_site(self.wordpress_url, self.wordpress_username, self.wordpress_password)
          if self.wordpress_importer.error == 'Login failed'
            self.errors.add(:wordpress_username, 'is invalid')
            self.errors.add(:wordpress_password, 'is invalid')
          else
            self.errors.add(:wordpress_url, 'is invalid')
            self.errors.add_to_base(self.wordpress_importer.error)
          end
        end

        unless self.wordpress_importer.error
          self.errors.add_to_base(self.wordpress_importer.error) unless self.wordpress_importer.import
        end
      end

      self.errors.length > 0 ? false : true
    end
  end

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
