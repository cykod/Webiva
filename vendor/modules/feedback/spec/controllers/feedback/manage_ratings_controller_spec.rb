require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"

require  File.expand_path(File.dirname(__FILE__)) + '/../../feedback_test_helper'

describe Feedback::ManageRatingsController do

  include FeedbackTestHelper

  reset_domain_tables :end_user,:feedback_end_user_ratings,:feedback_ratings

  before(:each) do
    mock_editor
    @user = create_end_user
    @user.save

    @test_class = TestTarget.new
    @test_class.id = 100

    @test_user_rating = FeedbackEndUserRating.create :end_user => @user, :rating => 5, :target_type => 'TestTarget', :target_id => @test_class.id
    @test_feedback_rating = FeedbackRating.with_target('TestTarget', @test_class.id).find(:first)
  end

  it "should handle table list" do 
      # Test all the permutations of an active table
    controller.should handle_active_table(:ratings_table) do |args|
      post 'ratings_table', args
    end
  end

  it "should handle table list" do 
      # Test all the permutations of an active table
    controller.should handle_active_table(:user_ratings_table) do |args|
      post 'user_ratings_table', args.merge(:path => [@user.id])
    end
  end

  it "should be able to delete a rating from ratings_table" do
    mock_editor

    assert_difference 'FeedbackEndUserRating.count', -1 do
      post 'ratings_table', :table_action => 'delete', :rating => {@test_user_rating.id => @test_user_rating.id}
      @test_feedback_rating.reload
      @test_feedback_rating.rating_sum.should == 0
      @test_feedback_rating.rating_count.should == 0
    end
  end

  it "should be able to delete a rating from user_ratings_table" do
    mock_editor

    assert_difference 'FeedbackEndUserRating.count', -1 do
      post 'user_ratings_table', :path => [@user.id], :table_action => 'delete', :rating => {@test_user_rating.id => @test_user_rating.id}
      @test_feedback_rating.reload
      @test_feedback_rating.rating_sum.should == 0
      @test_feedback_rating.rating_count.should == 0
    end
  end
end
