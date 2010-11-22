require 'nokogiri'

class ThemeBuilderFetcher
  def self.fetch(url)
    fetcher = ThemeBuilderFetcher.new
    fetcher.fetch url
  end

  def fetch(url)
    @url = url
    html = self.download url
    return false unless html

    # because nokogiri is case sensitive
    html.gsub!(/rel=(["'])stylesheet\1/i, 'rel=\1stylesheet\1')
    html.gsub!(/<body/i, '<body')
    html.gsub!(/<\/body/i, '</body')

    doc = Nokogiri::HTML(html)
    doc.css('script').remove()
    doc.css('iframe').remove()
    doc.css('#webiva-theme-builder').remove()
    inline_styles = doc.css('style').to_html
    doc.css('style').remove();

    base_href = doc.css('base').first
    @base_url = base_href.attributes['href'].to_s if base_href
    begin URI.parse @base_url rescue @base_url = nil end
    @base_url = url if @base_url.blank?

    css = ''
    doc.css('link').each do |link_tag|
      next unless link_tag.attributes['rel'].to_s.include?('stylesheet')
      href = link_tag.attributes['href'].to_s
      media = link_tag.attributes['media'].to_s
      unless href.blank?
        css += "\n@media #{media} {" unless media == 'screen' || media == ''
        css += self.fetch_css href
        css += "\n}" unless media == 'screen' || media == ''
      end
    end

    tmp_path = "#{RAILS_ROOT}/tmp/theme_builder/" + DomainModel.active_domain_id.to_s;
    FileUtils.mkpath(tmp_path)
    filename = tmp_path + "/styles.css"
    File.open(filename, 'w') { |f| f.write css }
    File.open(filename, 'r') do |f|
      DomainFile.create :filename => f, :parent_id => self.base_folder.id, :process_immediately => true
    end

    images = {}
    doc.css('img').each do |img_tag|
      orig_src = img_tag.attributes['src'].to_s
      next if orig_src.blank?

      src = self.construct_url(orig_src)
      images[orig_src] = images[src] if images[src]
      next if images[src]

      file = self.add_image self.construct_url(src)
      if file
        images[src] = file
        images[orig_src] = file
      end
    end

    doc.css('a').each do |anchor_tag|
      href = anchor_tag.attributes['href'].to_s
      next if href.blank? || href =~ /^(#|https?:|mailto:|javascript:)/i
      anchor_tag['href'] = self.construct_url href
    end

    body = doc.css('body').to_html
    images.each do |src, file|
      body.gsub!(/(['"])#{src}\1/, "\\1#{file}\\1")
    end

    html_file = nil
    tmp_path = "#{RAILS_ROOT}/tmp/theme_builder/" + DomainModel.active_domain_id.to_s;
    FileUtils.mkpath(tmp_path)
    filename = tmp_path + "/index.html"
    File.open(filename, 'w') { |f| f.write "<!DOCTYPE html>\n<html>\n<head>\n#{doc.css('meta').to_html}\n#{self.parse_css(@base_url, inline_styles)}\n</head>\n#{body}\n</html>" }
    File.open(filename, 'r') do |f|
      html_file = DomainFile.create :filename => f, :parent_id => self.base_folder.id
    end

    html_file
  end

  def theme_builder_folder
    @theme_builder_folder ||= DomainFile.push_folder('Theme Builder')
  end

  def base_folder
    @base_folder ||= DomainFile.push_folder self.uri.host, :parent_id => self.theme_builder_folder.id
  end

  def images_folder
    @images_folder ||= DomainFile.push_folder 'images', :parent_id => self.base_folder.id
  end

  def add_image(src)
    src_uri = nil
    begin
      src_uri = URI.parse src.strip
    rescue URI::InvalidURIError
      return src
    end

    folder = self.images_folder
    file_path = 'images'
    parts = src_uri.path.split('/')
    parts.shift
    parts.pop
    parts.shift if parts[0].to_s.downcase == 'images'
    parts.each do |part|
      file_path += "/#{part}"
      folder = DomainFile.push_folder part, :parent_id => folder.id
    end
    file = folder.add src
    return nil unless file
    file_path += "/#{file.name}"
    file_path
  end

  def download(url, content_type='text/html')
    begin
      response = DomainFile.download url
      response.body if response.code == "200" && response.content_type == content_type
    rescue
      nil
    end
  end

  def base_uri
    @base_uri ||= URI.parse @base_url
  end

  def uri
    @uri ||= URI.parse @url
  end

  def domain_link
    @domain_link ||= "#{self.base_uri.scheme}://#{self.base_uri.host}#{self.base_uri.port == 80 ? '' : (':' + self.base_uri.port.to_s)}"
  end

  def base_path
    return @domain_base if @domain_base
    path = self.base_uri.path
    path = '/' if path.blank?
    path = path.sub(/\/[^\/]+$/, '/')
    @domain_base = "#{path}"
  end

  def construct_url(path)
    if path =~ /^\//
      path = File.expand_path path
      "#{self.domain_link}#{path}"
    elsif path =~ /^http/
      path
    else
      path = File.expand_path "#{self.base_path}#{path}"
      "#{self.domain_link}#{path}"
    end
  end

  def fetch_css(href)
    css_url = self.construct_url(href)
    css = self.download(css_url, 'text/css')
    return '' unless css
    self.parse_css css_url, css
  end

  def parse_css(css_url, css)
    original_base_url = @base_url
    @base_uri = nil
    @domain_link = nil
    @domain_base = nil
    @base_url = css_url

    @imported_css_files ||= {}
    css.gsub!(/@import.*?[('"]+([^)"']+).+?;/).each do |match|
      url = self.construct_url($1)
      if @imported_css_files[url]
        ''
      else
        @imported_css_files[url] = true
        self.fetch_css(url)
      end
    end

    images = {}
    css.gsub!(/url\(["']?([^'"]+?)['"]?\)/) do |match|
      orig_src = $1
      src = self.construct_url(orig_src)
      images[orig_src] = images[src] if images[src]
      next if images[src]

      file = self.add_image src
      if file
        images[src] = file
        images[orig_src] = file
      end

      "url(#{file})"
    end

    @base_uri = nil
    @domain_link = nil
    @domain_base = nil
    @base_url = original_base_url

    css
  end
end
