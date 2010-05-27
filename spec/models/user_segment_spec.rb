require File.dirname(__FILE__) + "/../spec_helper"

describe UserSegment do

  reset_domain_tables :user_segments, :end_users

  before(:each) do
    @user1 = EndUser.push_target('test1@test.dev', :first_name => 'Doug', :activated => true)
    @user2 = EndUser.push_target('test2@test.dev', :last_name => 'Smith', :activated => true)
    @user3 = EndUser.push_target('test3@test.dev', :activated => true)
    @user4 = EndUser.push_target('test4@test.dev', :activated => false)
  end

  it "should require a name and a type" do
    @segment = UserSegment.new
    @segment.valid?.should be_false
    @segment.should have(1).error_on(:name)
    @segment.should have(2).error_on(:segment_type)
    @segment.should have(0).error_on(:segment_options_text)

    @segment = UserSegment.new :segment_type => 'filtered'
    @segment.valid?.should be_false
    @segment.should have(1).error_on(:name)
    @segment.should have(1).error_on(:segment_options_text)
  end

  it "should be able to create custom segments" do
    @segment = UserSegment.create :name => 'Test', :segment_type => 'custom'
    @segment.add_ids [@user1.id, @user2.id, @user3.id]
    @segment.ready?.should be_true
    @test_segment = UserSegment.find @segment.id
    @test_segment.end_user_ids.should == [@user1.id, @user2.id, @user3.id]

    @segment = UserSegment.find @segment.id
    @segment.remove_ids [@user1.id, @user3.id]
    @test_segment = UserSegment.find @segment.id
    @test_segment.end_user_ids.should == [@user2.id]
  end

  it "should be able to filter for users" do
    @segment = UserSegment.create :name => 'Test', :segment_type => 'filtered', :segment_options_text => 'activated.is(true)'
    @segment.should_refresh?.should be_true
    @segment.refresh
    @segment.ready?.should be_true
    @segment.end_user_ids.length.should == 3
    @segment.last_count.should == 3
    @segment.last_ran_at.should_not be_nil
  end
end
