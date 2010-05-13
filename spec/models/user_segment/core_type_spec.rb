require File.dirname(__FILE__) + "/../../spec_helper"

describe UserSegment::CoreType do

  reset_domain_tables :end_users

  describe "DateTimeType" do
    before(:each) do
      EndUser.push_target('test1@test.dev', :created_at => 2.days.ago)
      EndUser.push_target('test2@test.dev', :created_at => 5.days.ago)
      EndUser.push_target('test3@test.dev')

      @type = UserSegment::CoreType::DateTimeType
    end

    it "should return users using before" do
      @type.before(EndUser, :created_at, 1, 'day').count.should == 2
      @type.before(EndUser, :created_at, 3, 'days').count.should == 1
      @type.before(EndUser, :created_at, 6, 'days').count.should == 0
    end

    it "should return users using since" do
      @type.since(EndUser, :created_at, 1, 'day').count.should == 1
      @type.since(EndUser, :created_at, 3, 'days').count.should == 2
      @type.since(EndUser, :created_at, 6, 'days').count.should == 3
    end

    it "should return users using between" do
      @type.between(EndUser, :created_at, 1.day.ago, Time.now).count.should == 1
      @type.between(EndUser, :created_at, 3.day.ago, Time.now).count.should == 2
      @type.between(EndUser, :created_at, 6.day.ago, Time.now).count.should == 3
    end
  end

  describe "NumberType" do
    before(:each) do
      EndUser.push_target('test1@test.dev', :user_level => 1)
      EndUser.push_target('test2@test.dev', :user_level => 2)
      EndUser.push_target('test3@test.dev', :user_level => 3)
      EndUser.push_target('test4@test.dev', :user_level => 3)

      @type = UserSegment::CoreType::NumberType
    end

    it "should return users using greater_than" do
      @type.greater_than(EndUser, :user_level, 2).count.should == 2
      @type.greater_than(EndUser, :user_level, 3).count.should == 0
    end

    it "should return users using greater_than_or_equal_to" do
      @type.greater_than_or_equal_to(EndUser, :user_level, 1).count.should == 4
      @type.greater_than_or_equal_to(EndUser, :user_level, 2).count.should == 3
      @type.greater_than_or_equal_to(EndUser, :user_level, 4).count.should == 0
    end

    it "should return users using less_than" do
      @type.less_than(EndUser, :user_level, 1).count.should == 0
      @type.less_than(EndUser, :user_level, 2).count.should == 1
      @type.less_than(EndUser, :user_level, 4).count.should == 4
    end

    it "should return users using less_than_or_equal_to" do
      @type.less_than_or_equal_to(EndUser, :user_level, 1).count.should == 1
      @type.less_than_or_equal_to(EndUser, :user_level, 2).count.should == 2
      @type.less_than_or_equal_to(EndUser, :user_level, 3).count.should == 4
      @type.less_than_or_equal_to(EndUser, :user_level, 4).count.should == 4
    end

    it "should return users using equals" do
      @type.equals(EndUser, :user_level, 1).count.should == 1
      @type.equals(EndUser, :user_level, 2).count.should == 1
      @type.equals(EndUser, :user_level, 3).count.should == 2
      @type.is(EndUser, :user_level, 3).count.should == 2
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
      @type.like(EndUser, :email, 'test%@test.dev').count.should == 4
    end

    it "should return users using is" do
      @type.is(EndUser, :email, 'test1@test.dev').count.should == 1
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
      @type.is(EndUser, :activated, true).count.should == 3
      @type.is(EndUser, :activated, false).count.should == 1
    end
  end
end
