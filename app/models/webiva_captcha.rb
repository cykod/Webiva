
=begin rdoc
Captcha Handlers require 4 basic methods

class MyCaptcha
  # returns the result of validate. by default is true
  def valid?; @valid; end

  # test to see if the user passed captcha
  def validate
    @valid = self.params[:captcha_text] == self.captcha_phrase
  end

  # returns the captcha image to display
  def render(options={}); nil; end

  # returns the html to insert into the form
  def generate(options={})
    if self.controller.send(:myself).id
      nil
    else
      self.generate_phrase((options[:length] || 6).to_i)
      self.controller.send(:render_to_string, :partial => self.partial, :locals => {:captcha => self, :options => options})
    end
  end
end

=end

class WebivaCaptcha
  include HandlerActions

  def initialize(controller)
    captcha_handler = self.class.captcha_handler
    if captcha_handler
      @handler = captcha_handler.new(controller)
    end
  end

  def valid?
    @handler.valid?
  end

  def validate(options={})
    return true if options[:skip]

    @handler ? @handler.validate(options) : true
  end

  def validate_object(obj, options={})
    if self.validate(options)
      true
    else
      obj.captcha_invalid = true
      false
    end
  end

  def generate(options={})
    return true if options[:skip]

    @handler ? @handler.generate(options) : ''
  end

  def render(options={})
    @handler ? @handler.render(options) : nil
  end

  def self.captcha_handler
    return nil unless Configuration.options.captcha_handler

    handler_info = get_handler_info(:webiva, :captcha, Configuration.options.captcha_handler)
    return nil unless handler_info

    handler_info[:class]
  end

  def self.captcha_error_message
    return nil unless Configuration.options.captcha_handler

    handler_info = get_handler_info(:webiva, :captcha, Configuration.options.captcha_handler)
    return nil unless handler_info

    handler_info[:error_message]
  end

  module HandlerSupport
    attr_reader :controller, :session, :params

    def initialize(controller)
      @controller = controller
      @session = controller.session
      @params = controller.params
    end
  end

  class Session
    def initialize(session, session_key, max=20)
      @session = session
      @session_key = session_key
      @max = max
      @session[@session_key] ||= []
    end

    def has?(index)
      @session[@session_key].any? { |ele| ele[0] == index }
    end

    def add(index, *data)
      delete(index)

      @session[@session_key].unshift( [index, *data] )

      @session[@session_key].slice!( @max - size ) if size > @max
    end

    def size
      @session[@session_key].size
    end

    def delete(index)
      @session[@session_key].reject! { |ele| ele[0] == index }
      @session_data = nil
    end

    def get(index)
      return @session_data if @session_data && @session_data[0] == index
      @session_data = @session[@session_key].assoc(index)
    end

    def get_phrase(index)
      data = get(index)
      return nil if data.nil?
      data[1]
    end
  end

  module ModelSupport
    def self.append_features(mod) #:nodoc:
      super
      mod.send(:attr_accessor, :captcha_invalid)
      mod.send(:validate, Proc.new { |elm| elm.errors.add(:captcha, WebivaCaptcha.captcha_error_message) if elm.captcha_invalid })
    end
  end
end
