require File.dirname(__FILE__) + "/../spec_helper"

describe UserSubscriptionEntrySegmentField do
  reset_domain_tables :end_users, :user_subscriptions, :user_subscription_entries, :user_segments, :user_segment_caches

  it "should only have valid EndUser fields" do
    obj = UserSubscriptionEntrySegmentField.user_segment_fields_handler_info[:domain_model_class].new
    UserSubscriptionEntrySegmentField.user_segment_fields.each do |key, value|
      obj.has_attribute?(value[:field]).should be_true
      obj.respond_to?(value[:display_field]).should be_true
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

  it "has handler_data" do
    @user1 = EndUser.push_target('test1@test.dev', :first_name => 'First')
    @user2 = EndUser.push_target('test2@test.dev', :last_name => 'Last')
    @subscription1 = UserSubscription.create :name => 'Test1'
    @subscription2 = UserSubscription.create :name => 'Test2'
    UserSubscriptionEntry.create :user_subscription_id => @subscription1.id, :end_user_id => @user1.id
    UserSubscriptionEntry.create :user_subscription_id => @subscription2.id, :end_user_id => @user2.id

    UserSubscriptionEntrySegmentField.get_handler_data([@user1.id, @user2.id], [:tag]).size.should == 2
  end

  it "can output field data" do
    @user1 = EndUser.push_target('test1@test.dev', :first_name => 'First')
    @user2 = EndUser.push_target('test2@test.dev', :last_name => 'Last')
    @subscription1 = UserSubscription.create :name => 'Test1'
    @subscription2 = UserSubscription.create :name => 'Test2'
    UserSubscriptionEntry.create :user_subscription_id => @subscription1.id, :end_user_id => @user1.id
    UserSubscriptionEntry.create :user_subscription_id => @subscription2.id, :end_user_id => @user1.id
    UserSubscriptionEntry.create :user_subscription_id => @subscription2.id, :end_user_id => @user2.id

    handler_data = UserSubscriptionEntrySegmentField.get_handler_data([@user1.id, @user2.id], [:num_subscriptions, :user_subscription_id])
    UserSubscriptionEntrySegmentField.field_output(@user1, handler_data, :num_subscriptions).should == 2

    UserSubscriptionEntrySegmentField.user_segment_fields.each do |key, value|
      next if value[:search_only]
      UserSubscriptionEntrySegmentField.field_output(@user1, handler_data, key)
    end
  end

  it "should be able to sort on sortable fields" do
    @user1 = EndUser.push_target('test1@test.dev', :first_name => 'First')
    @user2 = EndUser.push_target('test2@test.dev', :last_name => 'Last')
    @subscription1 = UserSubscription.create :name => 'Test1'
    @subscription2 = UserSubscription.create :name => 'Test2'
    UserSubscriptionEntry.create :user_subscription_id => @subscription1.id, :end_user_id => @user1.id
    UserSubscriptionEntry.create :user_subscription_id => @subscription2.id, :end_user_id => @user1.id
    UserSubscriptionEntry.create :user_subscription_id => @subscription2.id, :end_user_id => @user2.id

    ids = [@user1.id, @user2.id]
    seg = UserSegment.create :name => 'Test', :segment_type => 'custom'
    seg.id.should_not be_nil
    seg.add_ids ids

    UserSubscriptionEntrySegmentField.user_segment_fields.each do |key, value|
      next unless value[:sortable]
      scope = UserSubscriptionEntrySegmentField.sort_scope(key.to_s, 'DESC')
      scope.should_not be_nil

      seg.order_by = key.to_s
      seg.sort_ids(ids).should be_true
      seg.status.should == 'finished'
      seg.end_user_ids.size.should == 2
    end
  end
end
