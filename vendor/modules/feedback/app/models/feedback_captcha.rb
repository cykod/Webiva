
require 'digest/md5'

class FeedbackCaptcha
  include WebivaCaptcha::HandlerSupport
  include SimpleCaptchaImage

  def self.webiva_captcha_handler_info
    { 
      :name => 'Feedback Captcha',
      :class => 'FeedbackCaptcha'
    }
  end

  def initialize(controller)
    super controller
    @captcha_session = WebivaCaptcha::Session.new self.session, self.class.to_s.underscore
    @valid = true
  end

  def validate(options={})
    @valid = false
    return @valid if self.params[:captcha_text].blank?
    @valid = self.params[:captcha_text] == self.phrase
  end

  def generate(options={})
    self.generate_phrase (options[:length] || 6).to_i
    self.controller.send(:render_to_string, :partial => '/feedback/captcha/feedback_captcha', :locals => {:captcha => self, :options => options})
  end

  def render(options={})
    return nil unless self.params[:path] && self.params[:path][0]
    @captcha_code = self.params[:path][0]
    controller.response.content_type = 'image/jpeg'
    generate_simple_captcha_image options
  end

  def captcha_code
    return @captcha_code if @captcha_code

    @captcha_code = self.params[:captcha_code] || Digest::MD5::hexdigest(rand.to_s)
  end

  def phrase
    @captcha_session.get_phrase self.captcha_code
  end

  def url
    "/website/feedback/captcha/image/#{self.captcha_code}"
  end

  def generate_phrase(length)
    chars = ('A'..'Z').to_a + ('0'..'9').to_a
    phrase = ((1..length).collect { |i| chars[rand(chars.size-1)] }).join
    @captcha_session.add self.captcha_code, phrase
  end

  def simple_captcha_value(key=nil)
    self.phrase
  end

  def valid?
    @valid
  end
end
