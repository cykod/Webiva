
class SimpleSiteWizardController < CmsController

  permit 'editor_structure_advanced'

  cms_admin_paths 'website'

  def self.structure_wizard_handler_info
    { :name => "Setup a Basic Site",
      :description => 'This wizard will setup a basic site.',
      :permit => "editor_structure_advanced",
      :url => { :controller => '/simple_site_wizard' }
    }
  end

  def index
    @version = SiteVersion.find_by_id(params[:version])
    SiteVersion.override_current(@version)

    cms_page_path [["Website", url_for(:controller => '/structure', :action => 'index', :version => @version.id)]], "Setup a Basic Site"

    @basic_wizard = SimpleSiteWizard.new params[:wizard]

    unless params[:wizard]
      @basic_wizard.pages = ['Home', 'About', 'News', 'Contact']
      @basic_wizard.name = DomainModel.active_domain_name.sub(/\.com$/, '').humanize
    end

    if request.post?
      if ! params[:commit] 
        redirect_to :controller => '/structure', :action => 'wizards', :version => @version.id
      elsif @basic_wizard.valid?
        @basic_wizard.add_to_site!
        flash[:notice] = "Setup a Basic Site"
        redirect_to :controller => '/structure', :version => @version.id
      end
    end
  end
end
