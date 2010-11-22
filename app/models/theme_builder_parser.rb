require 'nokogiri'

class ThemeBuilderParser < HashModel
  attributes :html_file_id => nil, :theme_html => nil, :theme_name => 'Theme Builder Theme', :url => nil, :setting_up_theme => false

  domain_file_options :html_file_id

  def strict?; true; end

  def is_html_file?
    self.html_file && self.html_file.mime_type == 'text/html'
  end

  def validate
    if self.html_file
      self.errors.add(:html_file_id, 'is invalid') unless self.html_file.mime_type == 'text/html'
    elsif ! self.url.blank?
      if URI::regexp(%w(http https)).match(self.url)
        if CMS_DEFAULTS['theme_builder_validate']
          uri = URI.parse self.url
          webiva_url = "#{uri.scheme}://#{uri.host}#{uri.port == 80 ? '' : (':' + uri.port.to_s)}/webiva.html"
          begin
            DomainFile.download(webiva_url)
          rescue
            self.errors.add(:url, "page not found #{webiva_url}")
          end
        end
      else
        self.errors.add(:url, 'is invalid') 
      end
    else
      self.errors.add(:html_file_id, 'is missing')
    end

    if self.setting_up_theme
      self.errors.add(:theme_html, 'is missing') if self.theme_html.blank?
      self.errors.add(:theme_name, 'is missing') if self.theme_name.blank?
    end
  end

  def images_folder
    @images_folder ||= DomainFile.push_folder 'images', :parent_id => self.html_file.parent.id
  end

  def css_file
    @css_file ||= DomainFile.find_by_parent_id_and_name self.html_file.parent.id, 'styles.css' if self.html_file
  end

  def editor_url(src)
    return src unless src =~ /^images/
    file = DomainFile.find_by_file_path self.images_folder.file_path + src.sub('images', '')
    file ? file.editor_url : src
  end

  def image_url(src)
    return src unless src=~ /^\/__fs__\/(.*)/
    file = DomainFile.find_by_prefix $1
    return src unless file

    url = file.name
    while file.parent && file.parent.name != 'images'
      url = "#{file.parent.name}/#{url}"
      file = file.parent
    end

    "images/#{url}"
  end

  def html
    return @html if @html

    File.open(self.html_file.filename, 'r') { |f| @html = f.read }

    @html = @html.gsub(/(['"])(images\/[^\1]+?)\1/) do |match|
      quote = $1
      src = $2
      "#{quote}#{self.editor_url(src)}#{quote}"
    end

    @html = @html.gsub(/url\((images\/[^\1]+?)\)/) do |match|
      src = $1
      "url(#{self.editor_url(src)})"
    end

    doc = Nokogiri::HTML(@html)

    doc.css('script').remove()
    doc.css('object').remove()
    doc.css('embed').remove()
    doc.css('#webiva-theme-builder').remove()

    @head = doc.css('meta').to_html + doc.css('style').to_html

    @html = doc.css('body').inner_html
  end

  def head
    self.html unless @head
    @head
  end

  def create_site_template
    self.theme_html = self.theme_html.gsub(/(['"])(\/__fs__\/[^\1]+?)\1/) do |match|
      quote = $1
      src = $2
      "#{quote}#{self.image_url(src)}#{quote}"
    end

    zones = []
    self.theme_html = self.theme_html.gsub(/<cms:zone name="(.*?)"><\/cms:zone>/) do |match|
      zone = $1
      zones << zone
      "<cms:zone name=\"#{zone}\"/>"
    end

    orderer_zones = []
    self.theme_html = self.theme_html.gsub(/ zone="(\d+)"/) do |match|
      orderer_zones << zones[$1.to_i]
      ''
    end

    self.theme_html = self.theme_html.gsub(/ class=""/, '')

    @head = self.head.gsub(/url\((\/__fs__\/.+?)\)/) do |match|
      src = $1
      "url(#{self.image_url(src)})"
    end

    site_template = SiteTemplate.create :template_type => 'site', :name => self.theme_name, :description => '', :template_html => self.theme_html, :style_design => self.style_design, :style_struct => self.style_struct, :domain_file_id => self.images_folder.id, :head => @head

    orderer_zones.each_with_index do |name, idx|
      site_template.site_template_zones.create :name => name, :position => (idx+1)
    end

    site_template
  end

  def css
    return @css if @css
    @css = ''
    File.open(self.css_file.filename, 'r') { |f| @css = f.read } if self.css_file
    @css
  end

  def style_design
    return @style_design if @style_design

    @style_struct = ''
    @style_design = self.css.gsub(/([#a-zA-Z0-9_\-\s,.:*]+#[#a-zA-Z0-9_\-\s,.:*]+)\s*(\{.*?\})/m) do |match|
      @style_struct += "#{$1} #{$2}\n\n"
      ''
    end

    @style_design
  end

  def style_struct
    @style_struct
  end

  def download
    file = ThemeBuilderFetcher.fetch self.url
    self.html_file_id = file.id if file && file.id
    file
  end

  def run_download(args)
    self.download
    {:successful => ! self.html_file_id.nil?, :html_file_id => self.html_file_id}
  end

  def editor_css(styles=nil)
    styles ||= self.css
    styles.gsub(/url\((images\/.+?)\)/) do |match|
      src = $1
      "url(#{self.editor_url(src)})"
    end
  end
end
