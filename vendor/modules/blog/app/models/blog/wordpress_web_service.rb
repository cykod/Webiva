require 'resthome'
require 'nokogiri'

class Blog::WordpressWebService < RESTHome
  attr_accessor :error

  headers 'User-Agent' => 'Mozilla/5.0 (Windows; U; Windows NT 6.1; ru; rv:1.9.2.3) Gecko/20100401 Firefox/4.0 (.NET CLR 3.5.30729)'

  def initialize(url, username, password)
    @uri = URI.parse(url.gsub(/\/$/, ''))
    @username = username
    @password = password
    self.base_uri = "#{@uri.scheme}://#{@uri.host}:#{@uri.port}"

    self.route :wp_login_get, "#{@uri.path}/wp-login.php", :method => :get, :return => :parse_login_page
    self.route :wp_login_post, "#{@uri.path}/wp-login.php", :method => :post, :return => :parse_login_page

    self.route :wp_export_get, "#{@uri.path}/wp-admin/export.php", :method => :get, :return => :parse_export_form
    self.route :wp_export, "#{@uri.path}/wp-admin/export.php", :method => :get
  end

  def parse_login_page(response)
    return @error = 'Login page not found' unless response.code == 200

    parent = Nokogiri::HTML.parse(response.body).css('body').first
    login_form = parent.css('#loginform')
    return @error = 'Login form not found' unless login_form.size > 0

    login_error = parent.css('#login_error')
    return @error = 'Login failed' if login_error.size > 0

    login_form = login_form.first
    @inputs = {}
    login_form.css('input').each do |input|
      next unless input.attributes['name']
      @inputs[input.attributes['name'].to_s] = (input.attributes['value'] || '').to_s
    end
  end

  def login
    self.wp_login_get
    return false if @inputs.nil?
    @inputs['log'] = @username
    @inputs['pwd'] = @password
    begin
      self.wp_login_post @inputs, :no_follow => true
    rescue HTTParty::RedirectionTooDeep => e
      save_cookies e.response.header.to_hash['set-cookie']
    end
    @error ? false : true
  end

  def parse_export_form(response)
    parent = Nokogiri::HTML.parse(response.body).css('body').first
    forms = parent.css('form')
    return @error = 'Export form not found' unless forms.size > 0
    export_form = forms.shift
    while export_form && export_form.css('#mm_start').length == 0
      export_form = forms.shift
    end
    return @error = 'Export form not found' unless export_form

    @inputs = {}
    export_form.css('input').each do |input|
      next unless input.attributes['name']
      @inputs[input.attributes['name'].to_s] = (input.attributes['value'] || '').to_s
    end

    export_form.css('select').each do |input|
      next unless input.attributes['name']
      value = ''
      input.css('option').each do |option|
        value = option.attributes['value'] if option.attributes['selected']
      end
      
      @inputs[input.attributes['name'].to_s] = (value || '').to_s
    end

    @inputs
  end

  def export
    self.wp_export_get
    return false if @error
    self.wp_export :query => @inputs, :format => :plain
    return self.response.body if self.response.headers['content-type'].to_s =~ /xml/
    false
  end
end
