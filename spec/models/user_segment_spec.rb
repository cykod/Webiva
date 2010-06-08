require File.dirname(__FILE__) + "/../spec_helper"

describe UserSegment do

  reset_domain_tables :user_segments, :end_users

  before(:each) do
    @user1 = EndUser.push_target('test1@test.dev', :created_at => 1.days.ago, :first_name => 'Doug', :activated => true)
    @user2 = EndUser.push_target('test2@test.dev', :created_at => 2.days.ago, :last_name => 'Smith', :activated => true)
    @user3 = EndUser.push_target('test3@test.dev', :created_at => 3.days.ago, :activated => true)
    @user4 = EndUser.push_target('test4@test.dev', :created_at => 4.days.ago, :activated => false)
    @user5 = EndUser.push_target('test5@test.dev', :created_at => 5.days.ago, :activated => false, :user_level => 2)
    @user6 = EndUser.push_target('test6@test.dev', :created_at => 6.days.ago, :last_name => 'Smith', :activated => true, :user_level => 3)
    @user7 = EndUser.push_target('test7@test.dev', :created_at => 7.days.ago, :first_name => 'Doug', :activated => false, :user_level => 1)
    @user8 = EndUser.push_target('test8@test.dev', :created_at => 8.days.ago, :first_name => 'Doug', :activated => true)
  end

  it "should require a name and a type" do
    @segment = UserSegment.new
    @segment.valid?.should be_false
    @segment.should have(1).error_on(:name)
    @segment.should have(1).error_on(:segment_type)
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
    size = UserSegmentCache::SIZE
    UserSegmentCache::SIZE = 2
    @segment = UserSegment.create :name => 'Test', :segment_type => 'filtered', :segment_options_text => 'activated.is(true)'
    @segment.should_refresh?.should be_true
    @segment.refresh
    @segment.ready?.should be_true
    @segment.end_user_ids.length.should == 5
    @segment.user_segment_caches.length.should == 3
    @segment.last_count.should == 5
    @segment.last_ran_at.should_not be_nil
    UserSegmentCache::SIZE = size
  end

  it "should be able to search through users" do
    size = UserSegmentCache::SIZE
    UserSegmentCache::SIZE = 2
    @segment = UserSegment.create :name => 'Test', :segment_type => 'filtered', :segment_options_text => 'activated.is(true)'
    @segment.should_refresh?.should be_true
    @segment.refresh
    @segment.ready?.should be_true
    @segment.end_user_ids.length.should == 5
    @segment.user_segment_caches.length.should == 3
    @segment.last_count.should == 5
    @segment.last_ran_at.should_not be_nil

    scope = EndUserCache.search 'doug'

    offset, users = @segment.search :scope => scope, :end_user_field => :end_user_id
    users.length.should == 2
    users[0].id.should == @user1.id
    users[1].id.should == @user8.id
    offset.should == 4

    offset, users = @segment.search :offset => 5, :scope => scope, :end_user_field => :end_user_id
    users.length.should == 0
    offset.should == 4 # because it is the index of the last element

    offset, users = @segment.search :scope => scope, :end_user_field => :end_user_id, :limit => 1
    users.length.should == 1
    users[0].id.should == @user1.id
    offset.should == 0

    offset, users = @segment.search :offset => 1, :scope => scope, :end_user_field => :end_user_id, :limit => 1
    users.length.should == 1
    users[0].id.should == @user8.id
    offset.should == 4

    offset, users = @segment.search :conditions => {:first_name => 'Doug'}
    users.length.should == 2
    users[0].id.should == @user1.id
    users[1].id.should == @user8.id
    offset.should == 4

    UserSegmentCache::SIZE = size
  end

  it "should be able to paginate through the segment" do
    size = UserSegmentCache::SIZE
    UserSegmentCache::SIZE = 2
    @segment = UserSegment.create :name => 'Test', :segment_type => 'filtered', :segment_options_text => 'activated.is(true)'
    @segment.should_refresh?.should be_true
    @segment.refresh
    @segment.ready?.should be_true
    @segment.end_user_ids.length.should == 5
    @segment.user_segment_caches.length.should == 3
    @segment.last_count.should == 5
    @segment.last_ran_at.should_not be_nil

    pages, users = @segment.paginate 1, :per_page => 2
    users.length.should == 2
    pages[:count].should == 2
    pages[:total].should == 5
    pages[:page].should == 1
    pages[:first].should == 1
    pages[:last].should == 2
    pages[:pages].should == 3

    pages, users = @segment.paginate 2, :per_page => 2
    users.length.should == 2
    pages[:count].should == 2
    pages[:total].should == 5
    pages[:page].should == 2
    pages[:first].should == 3
    pages[:last].should == 4
    pages[:pages].should == 3

    pages, users = @segment.paginate 3, :per_page => 2
    users.length.should == 1
    pages[:count].should == 1
    pages[:total].should == 5
    pages[:page].should == 3
    pages[:first].should == 5
    pages[:last].should == 5
    pages[:pages].should == 3

    # returns the last element again
    pages, users = @segment.paginate 4, :per_page => 2
    users.length.should == 1
    pages[:count].should == 1
    pages[:total].should == 5
    pages[:page].should == 3 # page is set to the last page
    pages[:first].should == 5
    pages[:last].should == 5
    pages[:pages].should == 3

    UserSegmentCache::SIZE = size
  end

  it "should be able to iterate over the users" do
    size = UserSegmentCache::SIZE
    UserSegmentCache::SIZE = 2
    @segment = UserSegment.create :name => 'Test', :segment_type => 'filtered', :segment_options_text => 'activated.is(true)'
    @segment.should_refresh?.should be_true
    @segment.refresh
    @segment.ready?.should be_true
    @segment.end_user_ids.length.should == 5
    @segment.user_segment_caches.length.should == 3
    @segment.last_count.should == 5
    @segment.last_ran_at.should_not be_nil

    @id_list = [@user1.id, @user2.id, @user3.id, @user6.id, @user8.id]

    cnt = 0
    @segment.each do |user|
      @id_list[cnt].should == user.id
      cnt = cnt.succ
    end
    cnt.should == @id_list.length

    @segment.each_with_index do |user,idx|
      user.id.should == @id_list[idx]
    end

    @segment.collect do |user|
      user.id
    end.should == @id_list

    user = @segment.find do |user|
      user.first_name == 'Doug'
    end

    user.id.should == @user1.id

    @user1.destroy

    user = @segment.find do |user|
      user.first_name == 'Doug'
    end

    user.id.should == @user8.id

    user = @segment.find do |user|
      user.first_name == 'Frank'
    end

    user.should be_nil

    UserSegmentCache::SIZE = size
  end

  it "should be able to change the ordering of the users" do
    @segment = UserSegment.create :name => 'Test', :segment_type => 'filtered', :segment_options_text => 'activated.is(true)'
    @segment.should_refresh?.should be_true
    @segment.refresh
    @segment.ready?.should be_true
    @segment.end_user_ids.length.should == 5

    @id_list = [@user1.id, @user2.id, @user3.id, @user6.id, @user8.id]
    @segment.end_user_ids.should == @id_list

    @segment.order_by = 'created'
    @segment.order_direction = 'ASC'
    @segment.should_refresh?.should be_true
    @segment.refresh
    @segment.end_user_ids.should == @id_list.reverse
  end
end
