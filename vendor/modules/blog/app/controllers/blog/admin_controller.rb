# Copyright (C) 2009 Pascal Rettig.

class Blog::AdminController < ModuleController
  permit 'blog_config'
  
  component_info('Blog',
                 :description => 'Add Blog Content Feature', 
                 :access => :public,
                 :dependencies => [ 'feedback'] )
  
                              
  content_model :blogs

  register_handler :structure, :wizard, "Blog::AddBlogWizard"
  register_handler :feed, :rss, "Blog::RssHandler"
  register_handler :feed, :rss, "Blog::MultipleRssHandler"
  register_handler :mail_manager, :generator, "Blog::ManageController"
  
  content_action  'Create a new Blog', { :controller => '/blog/admin', :action => 'create' }, :permit => 'blog_config'

  register_permission_category :blog, "Blog" ,"Permissions for Writing Blogs"
  
  register_permissions :blog, [ [ :config, 'Blog Configure', 'Can Configure Blogs'],
                                [ :writer, 'Blog Writer', 'Can Write Blogs'],
                                [ :user_blogs, 'User Blog Editor', 'Can Edit User Blogs' ]
                             ]

  public     

    def self.get_blogs_info
      info = Blog::BlogBlog.find(:all, :order => 'name', :conditions => { :is_user_blog => false }).collect do |blog|
        {:name => blog.name,:url => { :controller => '/blog/manage', :path => blog.id } ,:permission => { :model => blog, :permission =>  :edit_permission, :base => :blog_writer  }, :icon => 'icons/content/blogs_icon.png' }
      end
      @user_blogs = Blog::BlogBlog.count(:all,:conditions => {:is_user_blog => true })
      if @user_blogs > 0
         info << { :name => 'Site Blogs', :url => { :controller => '/blog/manage', :action => 'list' },:permission => 'blog_user_blogs', :icon => 'icons/content/blogs_icon.png' }
      end
      info
  end

  def create
    cms_page_info [ ["Content",url_for(:controller => '/content') ], "Create a new Blog"], "content"
    
    @blog = Blog::BlogBlog.new(params[:blog] || { :add_to_site => true })

    if(request.post? && params[:blog])
      if(@blog.save)
        if !@blog.add_to_site.blank?
          @version = SiteVersion.current
          redirect_to Blog::AddBlogWizard.wizard_url.merge(:blog_id => @blog.id, :version => @version.id)
          return
        else
          redirect_to :controller => '/blog/manage', :path => @blog.id
          return 
        end
      end
    end

  end
  
end
