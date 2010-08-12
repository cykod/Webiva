
class Feedback::CaptchaController < ApplicationController
  def image
    @captcha = WebivaCaptcha.new self
    set_cache_buster
    render :text => @captcha.render
  end
end

