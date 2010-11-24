
class WebivaNet::SimpleSiteWizard < Wizards::SimpleSite

  def self.structure_wizard_handler_info
    { :name => "Webiva.net Setup a Basic Site",
      :description => 'This wizard will setup a basic site with a theme.',
      :permit => "editor_structure_advanced",
      :url => self.wizard_url
    }
  end

  attributes :theme => nil

  validates_presence_of :theme

  options_form(
               fld(:theme, :select, :options => :theme_options)
               )

  def theme_options
    WebivaNet::Theme.themes.collect { |t| [t.name, t.guid] }
  end

  def create_simple_theme
    webiva_theme = WebivaNet::Theme.find_by_guid self.theme
    webiva_theme.install
    bundler = WebivaBundler.new :bundle_file_id => webiva_theme.bundle_file.id, :replace_same => true
    bundler.import
    SiteTemplate.last :conditions => ['parent_id IS NULL']
  end
end
