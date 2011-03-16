require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../spec/spec_helper"

require  File.expand_path(File.dirname(__FILE__)) + '/../feedback_test_helper'

describe Comment do

  include FeedbackTestHelper

  reset_domain_tables :comments, :end_users

  it "should require name and comment" do
    @comment = Comment.new
    @comment.valid?
    @comment.should have(1).errors_on(:comment)
    @comment.should have(1).errors_on(:target_type)
    @comment.should have(1).errors_on(:target_id)
  end

  it "should require name, comment, target" do
    @comment = Comment.new :name => 'Test', :comment => 'Test Comment', :target_type => 'test', :target_id => 1
    @comment.save.should be_true
    @comment.posted_at.should_not be_nil
  end

  it "can create a comment if a end_user is specified" do
    @user = create_end_user
    @comment = Comment.new :end_user => @user, :comment => 'Test Comment', :target_type => 'test', :target_id => 1
    @comment.save.should be_true
    @comment.posted_at.should_not be_nil
    @comment.name = @user.name
  end

end
