require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../spec/spec_helper"

require  File.expand_path(File.dirname(__FILE__)) + '/../feedback_test_helper'

describe FeedbackEndUserRating do

  include FeedbackTestHelper

  reset_domain_tables :feedback_end_user_ratings, :feedback_ratings, :end_users

  it "should require target" do
    user_rating = FeedbackEndUserRating.new
    user_rating.valid?

    user_rating.should have(1).errors_on(:target_type)
    user_rating.should have(1).errors_on(:target_id)
  end

  it "should be able to save a rating for anonymous user" do
    user_rating = FeedbackEndUserRating.new :target_type => 'TestTarget', :target_id => 1, :rating => 5
    user_rating.save.should be_true
    user_rating.rated_at.should_not be_nil
  end

  it "should be able to save a rating for a user" do
    user = create_end_user
    user_rating = FeedbackEndUserRating.new :target_type => 'TestTarget', :target_id => 1, :rating => 5, :end_user => user
    user_rating.save.should be_true
    user_rating.rated_at.should_not be_nil
    user_rating.end_user_id.should == user.id
  end

  it "should be correctly computing the average" do
    user_rating = FeedbackEndUserRating.new :target_type => 'TestTarget', :target_id => 1, :rating => 5
    user_rating.save.should be_true
    user_rating.feedback_rating.rating.should == 5

    feedback_rating = FeedbackRating.with_target('TestTarget', 1).find(:first)
    feedback_rating.rating_sum.should == 5
    feedback_rating.rating_count.should == 1

    user_rating.rating = 9
    user_rating.save.should be_true
    user_rating.feedback_rating.rating_sum.should == 9
    user_rating.feedback_rating.rating_count.should == 1
    FeedbackRating.with_target('TestTarget', 1).count == 1
    user_rating.feedback_rating.rating.should == 9

    feedback_rating.reload
    feedback_rating.rating_sum.should == 9
    feedback_rating.rating_count.should == 1

    user_rating = FeedbackEndUserRating.new :target_type => 'TestTarget', :target_id => 1, :rating => 7
    user_rating.save.should be_true
    user_rating.feedback_rating.rating_sum.should == 16
    user_rating.feedback_rating.rating_count.should == 2
    FeedbackRating.with_target('TestTarget', 1).count == 1
    user_rating.feedback_rating.rating.should == 8

    feedback_rating.reload
    feedback_rating.rating_sum.should == 16
    feedback_rating.rating_count.should == 2

    user_rating = FeedbackEndUserRating.new :target_type => 'TestTarget', :target_id => 1, :rating => 2
    user_rating.save.should be_true
    user_rating.feedback_rating.rating_sum.should == 18
    user_rating.feedback_rating.rating_count.should == 3
    FeedbackRating.with_target('TestTarget', 1).count == 1
    user_rating.feedback_rating.rating.should == 6

    feedback_rating.reload
    feedback_rating.rating_sum.should == 18
    feedback_rating.rating_count.should == 3

    user_rating.destroy
    user_rating.feedback_rating.rating_sum.should == 16
    user_rating.feedback_rating.rating_count.should == 2
    FeedbackRating.with_target('TestTarget', 1).count == 1
    user_rating.feedback_rating.rating.should == 8

    feedback_rating.reload
    feedback_rating.rating_sum.should == 16
    feedback_rating.rating_count.should == 2

    user_rating = FeedbackEndUserRating.new :target_type => 'TestTarget', :target_id => 1, :rating => 2
    user_rating.save.should be_true
    user_rating.feedback_rating.rating_sum.should == 18
    user_rating.feedback_rating.rating_count.should == 3
    FeedbackRating.with_target('TestTarget', 1).count == 1
    user_rating.feedback_rating.rating.should == 6

    feedback_rating.reload
    feedback_rating.rating_sum.should == 18
    feedback_rating.rating_count.should == 3

    user_rating.rating = 5
    user_rating.save.should be_true
    user_rating.feedback_rating.rating_sum.should == 21
    user_rating.feedback_rating.rating_count.should == 3
    FeedbackRating.with_target('TestTarget', 1).count == 1
    user_rating.feedback_rating.rating.should == 7

    feedback_rating.reload
    feedback_rating.rating_sum.should == 21
    feedback_rating.rating_count.should == 3

    duplicate_feedback_rating = FeedbackRating.new :target_type => 'TestTarget', :target_id => 1, :rating_sum => 4, :rating_count => 1
    duplicate_feedback_rating.save.should be_true

    user_rating = FeedbackEndUserRating.new :target_type => 'TestTarget', :target_id => 1, :rating => 3
    user_rating.save.should be_true
    user_rating.feedback_rating.rating_sum.should == 24
    user_rating.feedback_rating.rating_count.should == 4
    FeedbackRating.with_target('TestTarget', 1).count == 1
    user_rating.feedback_rating.rating.should == 6
  end
end
