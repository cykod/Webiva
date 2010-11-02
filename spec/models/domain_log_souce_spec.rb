require File.dirname(__FILE__) + "/../spec_helper"
require File.dirname(__FILE__) + "/../domain_log_spec_helper"

describe DomainLogSource do

  reset_domain_tables :domain_log_session, :domain_log_visitor, :domain_log_referrer, :domain_log_source

  queue_session_klass = nil
  begin
    queue_session_klass = Module.const_get('MarketCampaignQueueSession')
    reset_domain_tables :market_campaign_queue_session
  rescue NameError
  end

  before(:each) do
    setup_domain_log_sources
  end

  describe "Affiliate" do
    it "should detect affiliate source" do
      session = Factory(:domain_log_session, :affiliate => 'test')
      source = DomainLogSource.get_source(session)
      source.should_not be_nil
      source.source_handler.should == 'domain_log_source/affiliate'
    end
  end

  if queue_session_klass
    describe "Email Campaign" do
      it "should detect email source" do
        session = Factory(:domain_log_session)
        queue_session_klass.create :session_id => session.session_id, :entry_created_at => Time.now
        source = DomainLogSource.get_source(session)
        source.should_not be_nil
        source.source_handler.should == 'domain_log_source/email_campaign'
      end
    end
  end

  describe "Social Network" do
    it "should detect social network source" do
      referrer = Factory(:domain_log_referrer, :referrer_domain => 'www.facebook.com', :referrer_path => '/')
      session = Factory(:domain_log_session, :domain_log_referrer_id => referrer.id)
      source = DomainLogSource.get_source(session)
      source.should_not be_nil
      source.source_handler.should == 'domain_log_source/social_network'
    end
  end

  describe "Search" do
    it "should detect search source" do
      session = Factory(:domain_log_session, :query => 'test')
      source = DomainLogSource.get_source(session)
      source.should_not be_nil
      source.source_handler.should == 'domain_log_source/search'
    end    
  end

  describe "Referrer" do
    it "should detect referrer source" do
      referrer = Factory(:domain_log_referrer, :referrer_domain => 'www.test.com', :referrer_path => '/')
      session = Factory(:domain_log_session, :domain_log_referrer_id => referrer.id)
      source = DomainLogSource.get_source(session)
      source.should_not be_nil
      source.source_handler.should == 'domain_log_source/referrer'
    end
  end

  describe "Type-in" do
    it "should detect type-in source" do
      session = Factory(:domain_log_session)
      source = DomainLogSource.get_source(session)
      source.should_not be_nil
      source.source_handler.should == 'domain_log_source/type_in'
    end
  end
end
