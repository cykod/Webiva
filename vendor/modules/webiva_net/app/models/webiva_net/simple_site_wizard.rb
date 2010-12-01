
class WebivaNet::SimpleSiteWizard < Wizards::SimpleSite

  def self.structure_wizard_handler_info
    { :name => "Setup a Basic Site",
      :description => 'This wizard will setup a basic site with a theme.',
      :permit => "editor_structure_advanced",
      :url => self.wizard_url
    }
  end

  attributes :theme => nil, :replace_same => true

  boolean_options :replace_same
  validates_presence_of :theme

  def validate
    self.errors.add(:pages, 'are missing') if self.pages.blank?
  end

  def theme_options
    WebivaNet::Theme.themes.collect { |t| [t.name, t.guid] }
  end

  def create_simple_theme
    return @site_template if @site_template

    webiva_theme = WebivaNet::Theme.find_by_guid self.theme
    webiva_theme.install
    bundler = WebivaBundler.new :bundle_file_id => webiva_theme.bundle_file.id, :replace_same => self.replace_same
    bundler.import

    theme_data = bundler.data.find do |d|
      d['handler'] == 'site_template' && d['data']['id']
    end

    @site_template = SiteTemplate.find_by_id theme_data['data']['id']
    @site_template ||= SiteTemplate.last :conditions => 'parent_id IS NULL'
    @site_template
  end

  def options_partial; "/webiva_net/wizard/options"; end
end
