
class Feedback::CaptchaController < ApplicationController
  def image
    @captcha = WebivaCaptcha.new self
    render :text => @captcha.render
  end
end

