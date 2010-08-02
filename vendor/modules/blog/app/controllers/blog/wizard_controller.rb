# Copyright (C) 2010 Cykod LLC.

class Blog::WizardController < ModuleController
  
  permit 'blog_config'

  component_info 'Blog'
  
  cms_admin_paths 'website'

  def self.structure_wizard_handler_info
    { :name => "Add a Blog to your Site",
      :description => 'This wizard will add an existing blog to a url on your site.',
      :permit => "blog_config",
      :url => { :controller => '/blog/wizard' }
    }
  end

  def index
    @version = SiteVersion.find_by_id(params[:version])
    SiteVersion.override_current(@version)

    return redirect_to(:controller => '/blog/admin', :action => 'create', :version => @version.id) if Blog::BlogBlog.count == 0

    cms_page_path [[ "Website",url_for(:controller => '/structure', :action => 'index', :version => @version.id) ]],"Add a Blog to your site structure"

    @blog_wizard = Blog::AddBlogWizard.new(params[:wizard] || {  :blog_id => params[:blog_id].to_i})
    if request.post? 
      if !params[:commit] 
        redirect_to :controller => '/structure', :action => 'wizards', :version => @version.id
      elsif  @blog_wizard.valid?
        @blog_wizard.add_to_site!
        flash[:notice] = "Added blog to site"
        redirect_to :controller => '/structure', :version => @version.id
      end
    end
  end
  

end
