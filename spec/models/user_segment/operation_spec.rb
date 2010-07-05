require File.dirname(__FILE__) + "/../../spec_helper"

describe UserSegment::Operation do

  reset_domain_tables :end_users

  before(:each) do
    EndUser.push_target('test1@test.dev', :created_at => 2.days.ago, :activated => true)
    EndUser.push_target('test2@test.dev', :created_at => 5.days.ago, :activated => false)
    EndUser.push_target('test3@test.dev', :activated => false)
    EndUser.push_target('test4@test.dev', :activated => true)
    EndUser.push_target('test5@test.dev', :activated => false)
    EndUser.push_target('test6@test.dev', :created_at => 10.days.ago, :activated => true)
    EndUser.push_target('test7@test.dev', :activated => false)
  end

  it "should be able to get the count" do
    @field = UserSegment::Field.new :field => 'created', :operation => 'before', :arguments => [1, 'days']

    @operation = UserSegment::Operation.new nil, [@field]
    @operation.valid?.should be_true
    @operation.count.should == 3
    @operation.end_user_ids.length.should == 3
    @operation.to_a.should == [nil, @field.to_h]
    @operation.to_expr.should == 'created.before(1, "days")'
    @operation.to_builder.should == {:operator => nil, :field => 'created', :operation => 'before', :argument0 => 1, :argument1 => 'days'}

    @operation = UserSegment::Operation.new 'not', [@field]
    @operation.valid?.should be_true
    @operation.count.should == 4
    @operation.end_user_ids.length.should == 4
    @operation.to_a.should == ['not', @field.to_h]
    @operation.to_expr.should == 'not created.before(1, "days")'
    @operation.to_builder.should == {:operator => 'not', :field => 'created', :operation => 'before', :argument0 => 1, :argument1 => 'days'}
  end

  it "should be able to concat fields" do
    @field1 = UserSegment::Field.new :field => 'created', :operation => 'before', :arguments => [1, 'days']
    @field2 = UserSegment::Field.new :field => 'activated', :operation => 'is', :arguments => [false]

    @operation = UserSegment::Operation.new nil, [@field1, @field2]
    @operation.valid?.should be_true
    @operation.count.should == 7
    @operation.end_user_ids.length.should == 6
    @operation.to_a.should == [nil, @field1.to_h, @field2.to_h]
    @operation.to_expr.should == 'created.before(1, "days") + activated.is(false)'
    @operation.to_builder.should == {:operator => nil, :field => 'created', :operation => 'before', :argument0 => 1, :argument1 => 'days', :condition => 'or', :child => {:field => 'activated', :operation => 'is', :argument0 => false}}

    @operation = UserSegment::Operation.new 'not', [@field1, @field2]
    @operation.valid?.should be_true
    @operation.count.should == 7
    @operation.end_user_ids.length.should == 1
    @operation.to_a.should == ['not', @field1.to_h, @field2.to_h]
    @operation.to_expr.should == 'not created.before(1, "days") + activated.is(false)'
    @operation.to_builder.should == {:operator => 'not', :field => 'created', :operation => 'before', :argument0 => 1, :argument1 => 'days', :condition => 'or', :child => {:field => 'activated', :operation => 'is', :argument0 => false}}
  end
end
