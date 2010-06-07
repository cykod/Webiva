require File.dirname(__FILE__) + "/../spec_helper"

describe UserSubscriptionEntrySegmentField do
  it "should only have valid EndUser fields" do
    obj = UserSubscriptionEntrySegmentField.user_segment_fields_handler_info[:domain_model_class].new
    UserSubscriptionEntrySegmentField.user_segment_fields.each do |key, value|
      obj.has_attribute?(value[:field]).should be_true
    end
  end

  describe "UserSubscriptionType" do
    reset_domain_tables :user_subscriptions, :user_subscription_entries

    before(:each) do
      @subscription1 = UserSubscription.create :name => 'Test1'
      @subscription2 = UserSubscription.create :name => 'Test2'
      @subscription3 = UserSubscription.create :name => 'Test3'
      @subscription4 = UserSubscription.create :name => 'Test4'
      UserSubscriptionEntry.create :user_subscription_id => @subscription1.id, :end_user_id => 1
      UserSubscriptionEntry.create :user_subscription_id => @subscription1.id, :end_user_id => 2
      UserSubscriptionEntry.create :user_subscription_id => @subscription1.id, :end_user_id => 3
      UserSubscriptionEntry.create :user_subscription_id => @subscription1.id, :end_user_id => 4

      UserSubscriptionEntry.create :user_subscription_id => @subscription3.id, :end_user_id => 1
      UserSubscriptionEntry.create :user_subscription_id => @subscription3.id, :end_user_id => 2

      UserSubscriptionEntry.create :user_subscription_id => @subscription4.id, :end_user_id => 5
      UserSubscriptionEntry.create :user_subscription_id => @subscription4.id, :end_user_id => 6

      @type = UserSubscriptionEntrySegmentField::UserSubscriptionType
    end

    it "should be able to find user from their subscriptions" do
      @type.is(UserSubscriptionEntry, :end_user_id, :user_subscription_id, @subscription3.id).count.should == 2
    end
  end
end
