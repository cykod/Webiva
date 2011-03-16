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

    @field = UserSegment::Field.new :field => 'created', :operation => nil, :arguments => [1, 'days']
    @field.valid?.should be_false

    @field = UserSegment::Field.new :field => 'created', :operation => 'before', :arguments => [1, 'days'], :child => {:field => 'registered', :operation => 'is', :arguments => [true]}
    @field.valid?.should be_true

    @field = UserSegment::Field.new :field => 'user_level', :operation => 'is', :arguments => [[1]]
    @field.valid?.should be_true

    @field = UserSegment::Field.new :field => 'user_level', :operation => 'is', :arguments => [[2]]
    @field.valid?.should be_true
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

  it "should be able to create the expression" do
    @field = UserSegment::Field.new :field => 'created', :operation => 'before', :arguments => [1, 'days'], :child => {:field => 'activated', :operation => 'is', :arguments => [false], :child => {:field => 'email', :operation => 'like', :arguments => ['test%@test.dev']}}
    @field.valid?.should == true

    @field.to_expr.should == "created.before(1, \"days\").activated.is(false).email.like(\"test%@test.dev\")"
    @field.to_expr(:nochild => 1).should == "created.before(1, \"days\")"
  end

  it "should be able to create the builder hash" do
    @field = UserSegment::Field.new :field => 'created', :operation => 'before', :arguments => [1, 'days'], :child => {:field => 'activated', :operation => 'is', :arguments => [false], :child => {:field => 'email', :operation => 'like', :arguments => ['test%@test.dev']}}
    @field.valid?.should == true

    @field.to_builder.should == {:field => 'created', :operation => 'before', :condition => 'and', :argument0 => 1, :argument1 => 'days', :child => {:field => 'activated', :operation => 'is', :argument0 => false, :condition => 'and', :child => {:field => 'email', :operation => 'like', :argument0 => 'test%@test.dev'}}}


    @field.to_builder(:condition => 'with', :child => {:field => 'registered', :operation => 'is', :argument0 => true}).should == {:field => 'created', :operation => 'before', :condition => 'and', :argument0 => 1, :argument1 => 'days', :child => {:field => 'activated', :operation => 'is', :argument0 => false, :condition => 'and', :child => {:field => 'email', :operation => 'like', :argument0 => 'test%@test.dev', :condition => 'with', :child => {:field => 'registered', :operation => 'is', :argument0 => true}}}}
  end
end
