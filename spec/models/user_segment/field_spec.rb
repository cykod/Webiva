require File.dirname(__FILE__) + "/../../spec_helper"

describe UserSegment::Field do

  reset_domain_tables :end_users

  before(:each) do
    EndUser.push_target('test1@test.dev', :created_at => 2.days.ago, :activated => true)
    EndUser.push_target('test2@test.dev', :created_at => 5.days.ago, :activated => false)
    EndUser.push_target('test3@test.dev', :activated => false)
  end

  it "should be valid or invalid" do
    @field = UserSegment::Field.new :field => 'created', :operation => 'before', :arguments => [1, 'days']
    @field.valid?.should be_true

    @field = UserSegment::Field.new :field => 'created', :operation => 'invalid_operation', :arguments => [1, 'days']
    @field.valid?.should be_false
  end

  it "should be able to use handler" do
    @field = UserSegment::Field.new :field => 'created', :operation => 'before', :arguments => [1, 'days']

    @field.handler_class.should == EndUserSegmentField
    @field.domain_model_class.should == EndUser
    @field.end_user_field.should == :id
    @field.model_field.should == :created_at
    @field.type_class.should == UserSegment::CoreType::DateTimeType
    @field.operation_arguments.should == [:integer, :option]
    @field.valid_arguments?.should == true
    @field.valid?.should == true
  end

  it "should return the count" do
    @field = UserSegment::Field.new :field => 'created', :operation => 'before', :arguments => [1, 'days']

    @field.valid?.should == true
    @field.count.should == 2
    @field.end_user_ids.length.should == 2

    @field = UserSegment::Field.new :field => 'created', :operation => 'since', :arguments => [1, 'days']
    @field.valid?.should == true
    @field.count.should == 1
    @field.end_user_ids.length.should == 1
  end

  it "should work with children" do
    @field = UserSegment::Field.new :field => 'created', :operation => 'before', :arguments => [1, 'days'], :child => {:field => 'activated', :operation => 'is', :arguments => [true]}
    @field.valid?.should == true
    @field.count.should == 1
    @field.end_user_ids.length.should == 1

    @field = UserSegment::Field.new :field => 'created', :operation => 'before', :arguments => [1, 'days'], :child => {:field => 'activated', :operation => 'is', :arguments => [true], :child => {:field => 'email', :operation => 'like', :arguments => ['test%@test.dev']}}
    @field.valid?.should == true
    @field.count.should == 1
    @field.end_user_ids.length.should == 1

    @field = UserSegment::Field.new :field => 'created', :operation => 'before', :arguments => [1, 'days'], :child => {:field => 'activated', :operation => 'is', :arguments => [false], :child => {:field => 'email', :operation => 'like', :arguments => ['test%@test.dev']}}
    @field.valid?.should == true
    @field.count.should == 1
    @field.end_user_ids.length.should == 1
  end
end
