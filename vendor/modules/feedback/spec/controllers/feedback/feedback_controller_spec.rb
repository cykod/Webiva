require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"

require  File.expand_path(File.dirname(__FILE__)) + '/../../feedback_test_helper'

describe Feedback::FeedbackController do

  include FeedbackTestHelper

  reset_domain_tables :end_user,:comments

  before(:each) do
    mock_editor
    @user = create_end_user
    @user.save

    @test_class = TestTarget.new
    @test_class.id = 100

    @test_comment = Comment.create :end_user => @user, :comment => 'Test Comment', :target_type => 'TestTarget', :target_id => @test_class.id
  end

  it "should handle table list" do 
      # Test all the permutations of an active table
    controller.should handle_active_table(:comments_table) do |args|
      post 'comments_table', args
    end
  end

  it "should handle table list" do 
      # Test all the permutations of an active table
    controller.should handle_active_table(:user_comments_table) do |args|
      post 'user_comments_table', args.merge(:path => [ @user.id] )
    end
  end

end
