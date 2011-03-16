require File.dirname(__FILE__) + "/../spec_helper"

describe TriggeredAction do
  
  reset_domain_tables :triggered_actions, :end_users, :tags, 'tag_cache', :end_user_tags # make tag_cache a string to avoid tabilization

  before(:each) do
  end
  
  it "should be able perform the send email core action" do
    @act = TriggeredAction.create(:action_type => 'email', :action_module => 'trigger/core_trigger',
                                  :trigger_type => 'ContentPublication',:trigger_id => 1,
                                  :data => 
                                      Trigger::CoreTrigger::EmailTrigger::EmailOptions.new(
                                        :send_type  => 'message',
                                        :subject => 'Test Message Subject',
                                        :custom_message  => 'Test Message Body',
                                        :email_to => 'addresses',
                                        :email_addresses => 'test@webiva.com'
                                      ).to_hash)

    MailTemplateMailer.should_receive(:deliver_message_to_address).with('test@webiva.com','Test Message Subject',{ :html => 'Test Message Body' })


    @act.perform({},EndUser.new)
  end
  
  it "should be able perform the add tag core action" do
    user = EndUser.push_target('test@webiva.com')
    
    @act = TriggeredAction.create(:action_type => 'tag', :action_module => 'trigger/core_trigger',
                                  :trigger_type => 'ContentPublication',:trigger_id => 1,
                                  :data => Trigger::CoreTrigger::TagTrigger::TagOptions.new(:tags => 'Testerama').to_hash)

    @act.perform({},user)
    
    user.reload
    
    user.tag_names.should == 'Testerama'
  end
  
  it "should be able perform the set user referrer core action" do
   user = EndUser.push_target('test@webiva.com')
    
    @act = TriggeredAction.create(:action_type => 'referrer', :action_module => 'trigger/core_trigger',
                                  :trigger_type => 'ContentPublication',:trigger_id => 1,
                                  :data => Trigger::CoreTrigger::ReferrerTrigger::ReferrerOptions.new(:referrer => 'Test Referrer', :apply => 'all').to_hash)

    @act.perform({},user)
    
    user.reload
    
    user.referrer.should == 'Test Referrer'
  end 
  

end
