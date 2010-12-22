
class FeedbackTimedCaptcha
  include WebivaCaptcha::HandlerSupport

  def self.webiva_captcha_handler_info
    { 
      :name => 'Feedback Timed Captcha',
      :error_message => 'requires javascript to be enabled'
    }
  end

  def initialize(controller)
    super controller
    @valid = true
    @captcha_session = WebivaCaptcha::Session.new self.session, self.class.to_s.underscore
  end

  def valid?; @valid; end

  def render(options={}); nil; end

  def validate(options={})
    return true if self.controller.send(:myself).id
    @valid = false

    captcha_time = (self.params[:captcha_time] || 0).to_i
    session_time = self.get_time
    return @valid if captcha_time == 0 || session_time == 0

    now = Time.now.to_i
    @valid = (now - session_time) >= 5 && (captcha_time - session_time) == 5
  end

  def generate(options={})
    if self.controller.send(:myself).id
      nil
    else
      captcha_time = self.set_time
      self.controller.send(:render_to_string, :partial => self.partial, :locals => {:captcha => self, :options => options, :captcha_time => captcha_time})
    end
  end

  def captcha_code
    return @captcha_code if @captcha_code
    @captcha_code = self.params[:captcha_code] || Digest::MD5::hexdigest(rand.to_s)
  end

  # keep track of when the captcha was requested
  def set_time
    current_time = Time.now.to_i
    @captcha_session.add self.captcha_code, current_time
    current_time
  end

  def get_time
    (@captcha_session.get_phrase(self.captcha_code) || 0).to_i
  end

  def partial
    '/feedback/captcha/feedback_timed_captcha'
  end
end
