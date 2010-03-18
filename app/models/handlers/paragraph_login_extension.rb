

class Handlers::ParagraphLoginExtension
  cattr_accessor :logger
  @@logger = ActiveRecord::Base.logger

  def initialize(opts)
    @options = self.class.paragraph_options(opts)
  end

  # test to see if user is logged in
  # return true if render
  def logged_in(renderer, login_options)
    @renderer = renderer
    @login_options = login_options
    nil
  end

  # Process user submitted login data
  # return true if render
  def login(params)
  end

  # Delete extension cookies
  def logout
  end

  # Called before the feature is displayed
  def feature_data(data)
  end

  # Adds any feature related tags
  def feature_tags(c, data)
  end

  # Paragraph Setup options
  def self.paragraph_options(val={})
  end

  protected
  # mimic basic renderer functionality
  def myself
    @renderer.send(:myself)
  end

  def session
    @renderer.send(:session)
  end

  def cookies
    @renderer.send(:cookies)
  end

  def params
    @renderer.send(:params)
  end

  def process_login(user, remember=false)
    @renderer.send(:process_login, user, remember)
  end

  def process_logout
    @renderer.send(:process_logout)
  end

  def redirect_paragraph(*args)
    @renderer.send(:redirect_paragraph, *args)
    true
  end

  def render_paragraph(*args)
    @renderer.send(:render_paragraph, *args)
    true
  end

  def paragraph_action(*args)
    @renderer.send(:paragraph_action, *args)
  end
end
