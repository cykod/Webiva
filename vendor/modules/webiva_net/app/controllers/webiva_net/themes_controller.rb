
class WebivaNet::ThemesController < ModuleController

  component_info 'WebivaNet'

  permit 'editor_design_templates'

  layout 'manage'

 cms_admin_paths "options",
    "Themes" => { :controller => '/templates' }

  public

  def self.action_panel_templates_handler_info
    {
      :name => 'Webiva.new Themes',
      :links => [{:link => 'Import Webiva.net Themes', :controller => '/webiva_net/themes', :action => 'index', :role => 'editor_design_templates', :icon => 'view.gif'}]
    }
  end

  def index
    cms_page_path ['Options','Themes'],"Webiva.net Themes"
    @themes = WebivaNet::Theme.themes
  end

  def view
    guid = params[:guid]
    @theme = WebivaNet::Theme.find_by_guid guid
    render :partial => 'view'
  end

  def install
    guid = params[:guid]
    @theme = WebivaNet::Theme.find_by_guid guid
    @theme.install
    redirect_to :controller => '/templates', :action => 'import_bundle', :bundler => {:bundle_file_id => @theme.bundle_file.id}, :select => 1
  end

  def welcome
    render :partial => 'welcome'
  end
end
