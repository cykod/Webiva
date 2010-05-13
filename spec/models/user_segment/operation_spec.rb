require File.dirname(__FILE__) + "/../../spec_helper"

describe UserSegment::Operation do

  reset_domain_tables :end_users

  @handler = EndUserSegmentField.user_segment_fields_handler_info

  before(:each) do
    EndUser.push_target('test1@test.dev', :created_at => 2.days.ago, :activated => true)
    EndUser.push_target('test2@test.dev', :created_at => 5.days.ago, :activated => false)
    EndUser.push_target('test3@test.dev', :activated => false)
  end

  it "should be able to get the count" do
    @field = UserSegment::Field.new :field => 'created', :operation => 'before', :arguments => [1, 'days']
    @field.handler = @handler

    @operation = UserSegment::Operation.new nil, [@field]
    @operation.valid?.should be_true
    @operation.count.should == 2
    @operation.end_user_ids.length.should == 2

    @operation = UserSegment::Operation.new 'not', [@field]
    @operation.valid?.should be_true
    @operation.count.should == 1
    @operation.end_user_ids.length.should == 1
  end

  it "should be able to concat fields" do
    @field1 = UserSegment::Field.new :field => 'created', :operation => 'before', :arguments => [1, 'days']
    @field1.handler = @handler

    @field2 = UserSegment::Field.new :field => 'activated', :operation => 'is', :arguments => [false]
    @field2.handler = @handler

    @operation = UserSegment::Operation.new nil, [@field1, @field2]
    @operation.valid?.should be_true
    @operation.count.should == 4
    @operation.end_user_ids.length.should == 3

    @operation = UserSegment::Operation.new 'not', [@field1, @field2]
    @operation.valid?.should be_true
    @operation.count.should == 2
    @operation.end_user_ids.length.should == 0
  end
end
