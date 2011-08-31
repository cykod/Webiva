require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../spec/spec_helper"

require  File.expand_path(File.dirname(__FILE__)) + '/../feedback_test_helper'

describe FeedbackTimedCaptcha do

  include FeedbackTestHelper

  before(:each) do
    @session = {}
    @params = {}
    @controller = mock :session => @session, :params => @params, :myself => EndUser.default_user
    @captcha_session = WebivaCaptcha::Session.new @session, 'feedback_timed_captcha'
    WebivaCaptcha::Session.should_receive(:new).and_return(@captcha_session)
    @captcha = FeedbackTimedCaptcha.new @controller
  end

  it "should be able to set the server time in the session" do
    @phrase = @captcha.set_time
    @captcha_session.size.should == 1
  end

  it "should be able to generate" do
    @controller.should_receive(:render_to_string)
    @phrase = @captcha.generate
    @captcha_session.size.should == 1
  end

  it "should be valid by default" do
    @captcha.valid?.should be_true
  end

  it "should be invalid if no captcha text is specified" do
    @controller.should_receive(:render_to_string)
    @phrase = @captcha.generate
    @captcha_session.size.should == 1
    @captcha.validate.should be_false
    @captcha.valid?.should be_false
  end

  it "should be invalid if no captcha text is empty" do
    @params[:captcha_text] = ''
    @controller.should_receive(:render_to_string)
    @phrase = @captcha.generate
    @captcha_session.size.should == 1
    @captcha.validate.should be_false
    @captcha.valid?.should be_false
  end

  it "should be invalid if the wrong text is specified" do
    @params[:captcha_text] = '_xx_xx_/'
    @controller.should_receive(:render_to_string)
    @phrase = @captcha.generate
    @captcha_session.size.should == 1
    @captcha.validate.should be_false
    @captcha.valid?.should be_false
  end

  it "should be valid" do
    @controller.should_receive(:render_to_string)
    @captcha.generate
    @captcha_session.size.should == 1
    @params[:captcha_time] = @captcha.get_time + 5
    @server_time = 5.seconds.since
    Time.should_receive(:now).at_least(:once).and_return(@server_time)
    @captcha.validate.should be_true
    @captcha.valid?.should be_true
  end
end
