require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../spec/spec_helper"

require  File.expand_path(File.dirname(__FILE__)) + '/../feedback_test_helper'

describe FeedbackCaptcha do

  include FeedbackTestHelper

  before(:each) do
    @session = {}
    @params = {}
    @controller = mock :session => @session, :params => @params, :myself => EndUser.default_user
    @captcha_session = WebivaCaptcha::Session.new @session, 'feedback_captcha'
    WebivaCaptcha::Session.should_receive(:new).and_return(@captcha_session)
    @captcha = FeedbackCaptcha.new @controller
  end

  it "should be able to generate a captcha string" do
    @phrase = @captcha.generate_phrase 6
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

  it "should append the captcha_code to the url" do
    code = @captcha.captcha_code
    # Use regexp to match cache buster timestamp
    @captcha.url.should =~ /^\/website\/feedback\/captcha\/image\/#{code}/
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
    @phrase = @captcha.generate
    @captcha_session.size.should == 1
    @params[:captcha_text] = @captcha.phrase
    @captcha.validate.should be_true
    @captcha.valid?.should be_true
  end
end
