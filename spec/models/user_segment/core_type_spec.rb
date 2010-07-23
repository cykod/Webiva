require File.dirname(__FILE__) + "/../../spec_helper"

describe UserSegment::CoreType do

  reset_domain_tables :end_users, :end_user_caches, :end_user_actions

  describe "DateTimeType" do
    before(:each) do
      EndUser.push_target('test1@test.dev', :created_at => 2.days.ago)
      EndUser.push_target('test2@test.dev', :created_at => 5.days.ago)
      EndUser.push_target('test3@test.dev')

      @type = UserSegment::CoreType::DateTimeType
    end

    it "should return users using before" do
      @type.before(EndUser, :id, :created_at, 1, 'days').count.should == 2
      @type.before(EndUser, :id, :created_at, 3, 'days').count.should == 1
      @type.before(EndUser, :id, :created_at, 6, 'days').count.should == 0
    end

    it "should return users using since" do
      @type.since(EndUser, :id, :created_at, 1, 'days').count.should == 1
      @type.since(EndUser, :id, :created_at, 3, 'days').count.should == 2
      @type.since(EndUser, :id, :created_at, 6, 'days').count.should == 3
    end

    it "should return users using between" do
      @type.between(EndUser, :id, :created_at, 1.day.ago, Time.now).count.should == 1
      @type.between(EndUser, :id, :created_at, 3.day.ago, Time.now).count.should == 2
      @type.between(EndUser, :id, :created_at, 6.day.ago, Time.now).count.should == 3
    end
  end

  describe "NumberType" do
    before(:each) do
      @user1 = EndUser.push_target('test1@test.dev', :user_level => 1)
      @user2 = EndUser.push_target('test2@test.dev', :user_level => 2)
      @user3 = EndUser.push_target('test3@test.dev', :user_level => 3)
      @user4 = EndUser.push_target('test4@test.dev', :user_level => 3)

      EndUserAction.create :end_user_id => @user1.id, :level => 3, :renderer => 'editor/auth', :action => 'login'
      EndUserAction.create :end_user_id => @user1.id, :level => 4, :renderer => 'editor/auth', :action => 'login'
      EndUserAction.create :end_user_id => @user1.id, :level => 2, :renderer => 'editor/auth', :action => 'login'

      EndUserAction.create :end_user_id => @user2.id, :level => 3, :renderer => 'editor/auth', :action => 'login'
      EndUserAction.create :end_user_id => @user2.id, :level => 2, :renderer => 'editor/auth', :action => 'login'

      EndUserAction.create :end_user_id => @user3.id, :level => 1, :renderer => 'editor/auth', :action => 'login'
      EndUserAction.create :end_user_id => @user3.id, :level => 1, :renderer => 'editor/auth', :action => 'login'

      EndUserAction.create :end_user_id => @user4.id, :level => 3, :renderer => 'editor/auth', :action => 'login'

      @type = UserSegment::CoreType::NumberType
    end

    it "should return users using greater_than" do
      @type.is(EndUser, :id, :user_level, '>', 2).count.should == 2
      @type.is(EndUser, :id, :user_level, '>', 3).count.should == 0
    end

    it "should return users using greater_than_or_equal_to" do
      @type.is(EndUser, :id, :user_level, '>=', 1).count.should == 4
      @type.is(EndUser, :id, :user_level, '>=', 2).count.should == 3
      @type.is(EndUser, :id, :user_level, '>=', 4).count.should == 0
    end

    it "should return users using less_than" do
      @type.is(EndUser, :id, :user_level, '<', 1).count.should == 0
      @type.is(EndUser, :id, :user_level, '<', 2).count.should == 1
      @type.is(EndUser, :id, :user_level, '<', 4).count.should == 4
    end

    it "should return users using less_than_or_equal_to" do
      @type.is(EndUser, :id, :user_level, '<=', 1).count.should == 1
      @type.is(EndUser, :id, :user_level, '<=', 2).count.should == 2
      @type.is(EndUser, :id, :user_level, '<=', 3).count.should == 4
      @type.is(EndUser, :id, :user_level, '<=', 4).count.should == 4
    end

    it "should return users using equals" do
      @type.is(EndUser, :id, :user_level, '=', 1).count.should == 1
      @type.is(EndUser, :id, :user_level, '=', 2).count.should == 1
      @type.is(EndUser, :id, :user_level, '=', 3).count.should == 2
      @type.is(EndUser, :id, :user_level, '=', 3).count.should == 2
    end

    it "should be able to find users based on the sum" do
      @type.sum(EndUserAction, :end_user_id, :level, '>', 3).find(:all).size.should == 2
      @type.sum(EndUserAction, :end_user_id, :level, '>=', 3).find(:all).size.should == 3
      @type.sum(EndUserAction, :end_user_id, :level, '<', 3).find(:all).size.should == 1
    end

    it "should be able to find users based on the max" do
      @type.max(EndUserAction, :end_user_id, :level, '>', 3).find(:all).size.should == 1
      @type.max(EndUserAction, :end_user_id, :level, '>=', 3).find(:all).size.should == 3
      @type.max(EndUserAction, :end_user_id, :level, '<', 3).find(:all).size.should == 1
    end

    it "should be able to find users based on the min" do
      @type.min(EndUserAction, :end_user_id, :level, '>', 3).find(:all).size.should == 0
      @type.min(EndUserAction, :end_user_id, :level, '>=', 3).find(:all).size.should == 1
      @type.min(EndUserAction, :end_user_id, :level, '<', 3).find(:all).size.should == 3
    end

    it "should be able to find users based on the average" do
      @type.average(EndUserAction, :end_user_id, :level, '>', 3).find(:all).size.should == 0
      @type.average(EndUserAction, :end_user_id, :level, '>=', 3).find(:all).size.should == 2
      @type.average(EndUserAction, :end_user_id, :level, '<', 3).find(:all).size.should == 2
    end
  end

  describe "CountType" do
    before(:each) do
      @user1 = EndUser.push_target('test1@test.dev', :user_level => 1)
      @user2 = EndUser.push_target('test2@test.dev', :user_level => 2)
      @user3 = EndUser.push_target('test3@test.dev', :user_level => 3)
      @user4 = EndUser.push_target('test4@test.dev', :user_level => 3)

      EndUserAction.create :end_user_id => @user1.id, :level => 3, :renderer => 'editor/auth', :action => 'login'
      EndUserAction.create :end_user_id => @user1.id, :level => 4, :renderer => 'editor/auth', :action => 'login'
      EndUserAction.create :end_user_id => @user1.id, :level => 2, :renderer => 'editor/auth', :action => 'login'

      EndUserAction.create :end_user_id => @user2.id, :level => 3, :renderer => 'editor/auth', :action => 'login'
      EndUserAction.create :end_user_id => @user2.id, :level => 2, :renderer => 'editor/auth', :action => 'login'

      EndUserAction.create :end_user_id => @user3.id, :level => 1, :renderer => 'editor/auth', :action => 'login'
      EndUserAction.create :end_user_id => @user3.id, :level => 1, :renderer => 'editor/auth', :action => 'login'

      EndUserAction.create :end_user_id => @user4.id, :level => 3, :renderer => 'editor/auth', :action => 'login'

      @type = UserSegment::CoreType::CountType
    end

    it "should return users using count" do
      @type.count(EndUserAction, :end_user_id, :end_user_id, '>', 2).find(:all).size.should == 1
      @type.count(EndUserAction, :end_user_id, :end_user_id, '>=', 2).find(:all).size.should == 3
      @type.count(EndUserAction, :end_user_id, :end_user_id, '=', 1).find(:all).size.should == 1
    end
  end

  describe "StringType" do
    before(:each) do
      EndUser.push_target('test1@test.dev')
      EndUser.push_target('test2@test.dev')
      EndUser.push_target('test3@test.dev')
      EndUser.push_target('test4@test.dev')

      @type = UserSegment::CoreType::StringType
    end

    it "should return users using like" do
      @type.like(EndUser, :id, :email, 'test%@test.dev').count.should == 4
    end

    it "should return users using is" do
      @type.is(EndUser, :id, :email, 'test1@test.dev').count.should == 1
    end
  end

  describe "BooleanType" do
    before(:each) do
      EndUser.push_target('test1@test.dev', :activated => true)
      EndUser.push_target('test2@test.dev', :activated => true)
      EndUser.push_target('test3@test.dev', :activated => true)
      EndUser.push_target('test4@test.dev', :activated => false)

      @type = UserSegment::CoreType::BooleanType
    end

    it "should return users using is" do
      @type.is(EndUser, :id, :activated, true).count.should == 3
      @type.is(EndUser, :id, :activated, false).count.should == 1
    end
  end

  describe "MatchType" do
    before(:each) do
      EndUser.push_target('test1@test.dev', :first_name => 'Doug', :activated => true)
      EndUser.push_target('test2@test.dev', :last_name => 'Smith', :activated => true)
      EndUser.push_target('test3@test.dev', :activated => true)
      EndUser.push_target('test4@test.dev', :activated => false)

      @type = UserSegment::CoreType::MatchType
    end

    it "should return users using search" do
      @type.search(EndUserCache, :end_user_id, :data, 'doug').count.should == 1
      @type.search(EndUserCache, :end_user_id, :data, 'blah').count.should == 0
    end
  end
end
