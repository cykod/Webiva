require File.dirname(__FILE__) + "/../spec_helper"
require File.dirname(__FILE__) + "/../domain_log_spec_helper"

describe DomainLogSource do

  reset_domain_tables :domain_log_sessions, :domain_log_visitors, :domain_log_referrers, :domain_log_sources

  queue_session_klass = nil
  begin
    result = DomainModel.connection.execute "show tables like 'market_campaign_queue_sessions'"
    if result.num_rows > 0
      queue_session_klass = Module.const_get('MarketCampaignQueueSession')
      reset_domain_tables :market_campaign_queue_session
    end
  rescue NameError
  end

  before(:each) do
    DomainLogSource.delete_all
    setup_domain_log_sources
  end

  describe "Affiliate" do
    it "should detect affiliate source" do
      session = Factory(:domain_log_session, :affiliate => 'test')
      source = DomainLogSource.get_source(session)
      source.should_not be_nil
      source[:source_handler].should == 'domain_log_source/affiliate'
    end
  end

  if queue_session_klass
    describe "Email Campaign" do
      it "should detect email source" do
        SiteModule.should_receive(:module_enabled?).with('mailing').and_return(true)
        session = Factory(:domain_log_session)
        queue_session_klass.create :session_id => session.session_id, :entry_created_at => Time.now
        source = DomainLogSource.get_source(session, :from_email_campaign => true)
        source.should_not be_nil
        source[:source_handler].should == 'domain_log_source/email_campaign'
      end
    end
  end

  describe "Social Network" do
    it "should detect social network source" do
      referrer = Factory(:domain_log_referrer, :referrer_domain => 'facebook.com', :referrer_path => '/')
      session = Factory(:domain_log_session, :domain_log_referrer_id => referrer.id)
      source = DomainLogSource.get_source(session)
      source.should_not be_nil
      source[:source_handler].should == 'domain_log_source/social_network'
    end
  end

  describe "Search" do
    it "should detect search source" do
      session = Factory(:domain_log_session, :query => 'test')
      source = DomainLogSource.get_source(session)
      source.should_not be_nil
      source[:source_handler].should == 'domain_log_source/search'
    end    
  end

  describe "Referrer" do
    it "should detect referrer source" do
      referrer = Factory(:domain_log_referrer, :referrer_domain => 'www.test.com', :referrer_path => '/')
      session = Factory(:domain_log_session, :domain_log_referrer_id => referrer.id)
      source = DomainLogSource.get_source(session)
      source.should_not be_nil
      source[:source_handler].should == 'domain_log_source/referrer'
    end
  end

  describe "Type-in" do
    it "should detect type-in source" do
      session = Factory(:domain_log_session)
      source = DomainLogSource.get_source(session)
      source.should_not be_nil
      source[:source_handler].should == 'domain_log_source/type_in'
    end
  end

  describe "Sessions" do
    before(:each) do
      @page = SiteVersion.default.root_node.push_subpage('')
      @visitor = Factory(:domain_log_visitor)
      @session = {:domain_log_visitor => {:id => @visitor.id}}
      @request = mock :session_options => {:id => 'xxxxxxx'}, :remote_ip => '127.0.0.1', :referrer => '', :parameters => {}
      @myself = EndUser.new
    end

    it "should not set the source if ignored" do
      assert_difference 'DomainLogSession.count', 1 do
        DomainLogSession.start_session(@myself, @session, @request, @page, true)
      end
      ses = DomainLogSession.last
      ses.domain_log_source_id.should be_nil
    end

    it "should set the source if not ignored" do
      assert_difference 'DomainLogSession.count', 1 do
        DomainLogSession.start_session(@myself, @session, @request, @page, false)
      end
      ses = DomainLogSession.last
      source = DomainLogSource.find_by_name 'Type-in'
      ses.domain_log_source_id.should == source.id
    end
  end
end
