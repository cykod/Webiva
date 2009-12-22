require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../spec/spec_helper"

require  File.expand_path(File.dirname(__FILE__)) + '/../feedback_test_helper'

describe FeedbackRating do

  include FeedbackTestHelper

  reset_domain_tables :feedback_end_user_ratings, :feedback_ratings, :end_users

  it "should require target and user_rating" do
    rating = FeedbackRating.new
    rating.valid?

    rating.should have(1).errors_on(:target_type)
    rating.should have(1).errors_on(:target_id)
  end

  it "should be able to save a rating" do
    rating = FeedbackRating.new :target_type => 'TestTarget', :target_id => 1
    rating.save.should be_true
  end
end
