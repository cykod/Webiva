require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"

require  File.expand_path(File.dirname(__FILE__)) + '/../../feedback_test_helper'

describe Feedback::ManageRatingsController do

  include FeedbackTestHelper

  reset_domain_tables :end_user,:feedback_end_user_ratings,:feedback_ratings

  before(:each) do
    @user = create_end_user
    @user.save

    @test_class = TestTarget.new
    @test_class.id = 100

    @test_rating = FeedbackEndUserRating.create :end_user => @user, :rating => 5, :target_type => 'TestTarget', :target_id => @test_class.id
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
      post 'user_ratings_table', args
    end
  end

end
