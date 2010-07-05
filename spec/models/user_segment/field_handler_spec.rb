require File.dirname(__FILE__) + "/../../spec_helper"

describe UserSegment::FieldHandler do

  it "should be able to register a field" do
    UserSegment::FieldHandler.register_field(:created, UserSegment::CoreType::DateTimeType, :field => :created_at)
    UserSegment::FieldHandler.has_field?(:created).should be_true
    UserSegment::FieldHandler.user_segment_fields[:created][:field].should == :created_at
    UserSegment::FieldHandler.user_segment_fields[:created][:type].should == UserSegment::CoreType::DateTimeType
    UserSegment::FieldHandler.user_segment_fields[:created][:name].should == 'Created'

    UserSegment::FieldHandler.register_field(:created, UserSegment::CoreType::DateTimeType, :field => :created_at, :name => 'EndUser.created')
    UserSegment::FieldHandler.has_field?(:created).should be_true
    UserSegment::FieldHandler.user_segment_fields[:created][:field].should == :created_at
    UserSegment::FieldHandler.user_segment_fields[:created][:type].should == UserSegment::CoreType::DateTimeType
    UserSegment::FieldHandler.user_segment_fields[:created][:name].should == 'EndUser.created'
  end

  it "should always return the EndUserSegmentField as the first handler" do
    UserSegment::FieldHandler.handlers[0][:class] == EndUserSegmentField
  end
end
