require File.dirname(__FILE__) + "/../../spec_helper"

describe UserSegment::Filter do

  reset_domain_tables :end_users

  before(:each) do
    @user1 = EndUser.push_target('test1@test.dev', :created_at => 2.days.ago, :activated => true, :user_level => 1)
    @user2 = EndUser.push_target('test2@test.dev', :created_at => 5.days.ago, :activated => false, :user_level => 2)
    @user3 = EndUser.push_target('test3@test.dev', :activated => false, :user_level => 3)
    @user4 = EndUser.push_target('test4@test.dev', :activated => true, :user_level => 1)
    @user5 = EndUser.push_target('test5@test.dev', :activated => false, :user_level => 2)
    @user6 = EndUser.push_target('test6@test.dev', :created_at => 10.days.ago, :activated => true, :user_level => 3)
    @user7 = EndUser.push_target('test7@test.dev', :activated => false, :user_level => 1)
  end

  it "should return the end user ids from a given set of options" do
    @operations = UserSegment::Filter.new
    options = [[nil, {:field => 'created', :operation => 'since', :arguments => [3, 'days'], :child => nil}]]
    @operations.operations = options
    @operations.valid?.should == true
    @operations.to_a.should == options
    @operations.end_user_ids.length.should == 5
  end

  it "should be able to refine end user ids based on multiple operations" do
    @operations = UserSegment::Filter.new
    options = [
      [nil, {:field => 'created', :operation => 'since', :arguments => [3, 'days'], :child => nil}],
      [nil, {:field => 'activated', :operation => 'is', :arguments => [true], :child => nil}]
    ]
    @operations.operations = options
    @operations.valid?.should == true
    @operations.to_a.should == options
    @operations.end_user_ids.length.should == 2
  end

  it "should return the end user ids from a given set operations syntax" do
    @operations = UserSegment::Filter.new
    options = [[nil, {:field => 'created', :operation => 'since', :arguments => [3, 'days'], :child => nil}]]
    code = <<-CODE
    created.since(3, "days")
    CODE
    @operations.parse(code).should be_true
    @operations.valid?.should == true
    @operations.to_a.should == options
    @operations.end_user_ids.length.should == 5

    @operations = UserSegment::Filter.new
    options = [['not', {:field => 'created', :operation => 'since', :arguments => [3, 'days'], :child => nil}]]
    code = <<-CODE
    not created.since(3, "days")
    CODE
    @operations.parse(code).should be_true
    @operations.valid?.should == true
    @operations.to_a.should == options
    @operations.end_user_ids.length.should == 2
  end

  it "should be able to refine end user ids with multiple operations" do
    @operations = UserSegment::Filter.new
    options = [
      [nil, {:field => 'created', :operation => 'since', :arguments => [3, 'days'], :child => nil}],
      [nil, {:field => 'activated', :operation => 'is', :arguments => [true], :child => nil}]
    ]
    code = <<-CODE
    created.since(3, "days")
    activated.is(true)
    CODE
    @operations.parse(code).should be_true
    @operations.valid?.should == true
    @operations.to_a.should == options
    @operations.end_user_ids.length.should == 2
    @operations.end_user_ids.include?(@user1.id).should be_true
    @operations.end_user_ids.include?(@user4.id).should be_true

    @operations = UserSegment::Filter.new
    options = [
      ['not', {:field => 'created', :operation => 'since', :arguments => [3, 'days'], :child => nil}],
      [nil, {:field => 'activated', :operation => 'is', :arguments => [true], :child => nil}]
    ]
    code = <<-CODE
    not created.since(3, "days")
    activated.is(true)
    CODE
    @operations.parse(code).should be_true
    @operations.valid?.should == true
    @operations.to_a.should == options
    @operations.end_user_ids.length.should == 1
    @operations.end_user_ids.include?(@user6.id).should be_true

    @operations = UserSegment::Filter.new
    options = [
      ['not', {:field => 'created', :operation => 'since', :arguments => [3, 'days'], :child => nil}, {:field => 'user_level', :operation => 'is', :arguments => [[1]], :child => nil}],
      [nil, {:field => 'activated', :operation => 'is', :arguments => [true], :child => nil}]
    ]
    code = <<-CODE
    not created.since(3, "days") + user_level.is([1])
    activated.is(true)
    CODE
    @operations.parse(code).should be_true
    @operations.valid?.should == true
    @operations.to_a.should == options
    @operations.end_user_ids.length.should == 1
    @operations.end_user_ids.include?(@user6.id).should be_true
    @operations.to_expr.should == "not created.since(3, \"days\") + user_level.is([1])\nactivated.is(true)"
    @operations.to_builder.should == {:operator => 'not', :condition => 'or', :field => 'created', :operation => 'since', :argument0 => 3, :argument1 => 'days', :child => {:field => 'user_level', :operation => 'is', :argument0 => [1], :condition => 'with', :child => {:operator => nil, :field => 'activated', :operation => 'is', :argument0 => true}}}
  end
end
