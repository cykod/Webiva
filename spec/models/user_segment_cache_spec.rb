require File.dirname(__FILE__) + "/../spec_helper"

describe UserSegmentCache do

  reset_domain_tables :user_segments, :user_segment_caches, :end_users

  before(:each) do
    @user1 = EndUser.push_target('test1@test.dev', :first_name => 'Doug', :activated => true)
    @user2 = EndUser.push_target('test2@test.dev', :last_name => 'Smith', :activated => true)
    @user3 = EndUser.push_target('test3@test.dev', :activated => true)
    @user4 = EndUser.push_target('test4@test.dev', :activated => false)
    @user5 = EndUser.push_target('test5@test.dev', :activated => false, :user_level => 2)
    @user6 = EndUser.push_target('test6@test.dev', :created_at => 10.days.ago, :last_name => 'Smith', :activated => true, :user_level => 3)
    @user7 = EndUser.push_target('test7@test.dev', :first_name => 'Doug', :activated => false, :user_level => 1)
    @user8 = EndUser.push_target('test8@test.dev', :first_name => 'Doug', :activated => true)

    @id_list = [@user7.id, @user2.id, @user1.id, @user5.id, @user4.id, @user6.id, @user3.id]
  end

  def new_cache
    UserSegmentCache.new :user_segment_id => 1, :position => 0, :id_list => @id_list
  end

  it "should require a user segment" do
    @cache = UserSegmentCache.new
    @cache.valid?.should be_false
    @cache.should have(1).error_on(:user_segment_id)
  end

  it "should be able fetch users" do
    @cache = new_cache

    # all users
    users = @cache.fetch_users
    users.each_with_index do |user, idx|
      user.id.should == @id_list[idx]
    end

    users = @cache.fetch_users(:offset => 0, :limit => 1000)
    users.each_with_index do |user, idx|
      user.id.should == @id_list[idx]
    end
    users[7].should be_nil

    users = @cache.fetch_users(:offset => 3, :limit => 2)
    users[0].id.should == @user5.id
    users[1].id.should == @user4.id
    users[2].should be_nil

    users = @cache.fetch_users(:offset => 10, :limit => 100)
    users.empty?.should be_true

    users = @cache.fetch_users(:offset => 6, :limit => 100000)
    users[0].id.should == @user3.id
    users[1].should be_nil
  end

  it "should be able to search through a cache" do
    @cache = new_cache

    scope = EndUserCache.search 'doug'

    offset, ids = @cache.search 0, :scope => scope, :end_user_field => :end_user_id, :batch_size => 2
    offset.should == 2
    ids.length.should == 2
    ids[0].should == @user7.id
    ids[1].should == @user1.id

    offset, ids = @cache.search 3, :scope => scope, :end_user_field => :end_user_id, :batch_size => 2
    ids.length.should == 0
    offset.should == (@id_list.length-1)

    offset, ids = @cache.search 7, :scope => scope, :end_user_field => :end_user_id, :batch_size => 2
    ids.length.should == 0
    offset.should == (@id_list.length-1)

    offset, ids = @cache.search 0, :limit => 1, :scope => scope, :end_user_field => :end_user_id, :batch_size => 2
    offset.should == 0
    ids.length.should == 1
    ids[0].should == @user7.id

    offset, ids = @cache.search 2, :limit => 1, :scope => scope, :end_user_field => :end_user_id, :batch_size => 1
    offset.should == 2
    ids.length.should == 1
    ids[0].should == @user1.id

    offset, ids = @cache.search 2, :limit => 1, :scope => scope, :end_user_field => :end_user_id
    offset.should == 2
    ids.length.should == 1
    ids[0].should == @user1.id
  end

  it "should be able to process users in caches" do
    @cache = new_cache

    cnt = 0
    @cache.each do |user|
      @id_list[cnt].should == user.id
      cnt = cnt.succ
    end
    cnt.should == @id_list.length

    (1..@id_list.length).each do |batch_size|
      cnt = 0
      @cache.each(:batch_size => batch_size) do |user|
        @id_list[cnt].should == user.id
        cnt = cnt.succ
      end
      cnt.should == @id_list.length
    end

    @cache.each_with_index do |user,idx|
      user.id.should == @id_list[idx]
    end

    @cache.collect do |user|
      user.id
    end.should == @id_list

    user = @cache.find(:batch_size => 2) do |user|
      user.first_name == 'Doug'
    end

    user.id.should == @user7.id

    @user7.destroy

    user = @cache.find(:batch_size => 2) do |user|
      user.first_name == 'Doug'
    end

    user.id.should == @user1.id

    user = @cache.find(:batch_size => 2) do |user|
      user.first_name == 'Frank'
    end

    user.should be_nil
  end
end
