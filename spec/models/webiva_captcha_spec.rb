require File.dirname(__FILE__) + "/../spec_helper"

describe WebivaCaptcha do

  describe "test session" do
    before(:each) do
      @session = {}
      @captcha_session = WebivaCaptcha::Session.new @session, 'captcha', 10
    end

    it "should only keep 10 captcha codes" do
      (1..20).each do |idx|
	@captcha_session.add(idx, "code#{idx}")
      end

      @captcha_session.size.should == 10
      @captcha_session.has?(19).should be_true
      @captcha_session.get_phrase(11).should == 'code11'
      @captcha_session.get_phrase(19).should == 'code19'
      @captcha_session.get_phrase(20).should == 'code20'
      @captcha_session.get_phrase(1).should be_nil
      @captcha_session.get_phrase(10).should be_nil

      @captcha_session.delete 1
      @captcha_session.size.should == 10

      @captcha_session.delete 20
      @captcha_session.size.should == 9
      @captcha_session.get_phrase(20).should be_nil
    end
  end
end
