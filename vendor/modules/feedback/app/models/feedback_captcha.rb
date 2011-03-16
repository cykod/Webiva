
require 'digest/md5'

class FeedbackCaptcha
  include WebivaCaptcha::HandlerSupport
  include SimpleCaptchaImage

  def self.webiva_captcha_handler_info
    { 
      :name => 'Feedback Captcha'
    }
  end

  def initialize(controller)
    super controller
    @captcha_session = WebivaCaptcha::Session.new self.session, self.class.to_s.underscore
    @valid = true
  end

  def validate(options={})
    return true if self.controller.send(:myself).id
    @valid = false
    return @valid if self.params[:captcha_text].blank? || self.phrase.blank?
    @valid = self.params[:captcha_text].downcase == self.phrase.downcase
  end

  def generate(options={})
    if self.controller.send(:myself).id
      nil
    else
      self.generate_phrase((options[:length] || 6).to_i)
      self.controller.send(:render_to_string, :partial => self.partial, :locals => {:captcha => self, :options => options})
    end
  end

  def render(options={})
    return nil unless self.params[:path] && self.params[:path][0]
    @captcha_code = self.params[:path][0]
    if self.phrase
      controller.response.content_type = 'image/jpeg'
      generate_simple_captcha_image options
    else
      controller.response.content_type = 'image/jpeg'
      generate_invalid_captcha_image
    end
  end

  def captcha_code
    return @captcha_code if @captcha_code

    @captcha_code = self.params[:captcha_code] || Digest::MD5::hexdigest(rand.to_s)
  end

  def phrase
    @captcha_session.get_phrase self.captcha_code
  end

  def url
    "/website/feedback/captcha/image/#{self.captcha_code}?Z=#{Time.now.to_i}"
  end

  def partial
    '/feedback/captcha/feedback_captcha'
  end

  def generate_phrase(length)
    chars = ('A'..'Z').to_a + ('1'..'9').to_a - ['O']
    phrase = ((1..length).collect { |i| chars[rand(chars.size-1)] }).join
    @captcha_session.add self.captcha_code, phrase
  end

  def simple_captcha_value(key=nil)
    self.phrase
  end

  def valid?
    @valid
  end

  def generate_invalid_captcha_image  #:nodoc
    @image = Magick::Image.new(110, 30) do 
      self.background_color = 'white'
      self.format = 'JPG'
    end
    color = 'black'
    text = Magick::Draw.new
    text.annotate(@image, 0, 0, 0, 5, 'Invalid Captcha'.t) do
      self.font_family = 'arial'
      self.font_weight = Magick::BoldWeight
      self.pointsize = 15
      self.fill = color
      self.gravity = Magick::CenterGravity
    end
    @image.implode(0).to_blob
  end
end
