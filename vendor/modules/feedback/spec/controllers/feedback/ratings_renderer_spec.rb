require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"

require  File.expand_path(File.dirname(__FILE__)) + '/../../feedback_test_helper'

describe Feedback::RatingsRenderer, :type => :controller do

  include FeedbackTestHelper

  controller_name :page

  integrate_views

  reset_domain_tables :end_users, :feedback_end_user_ratings, :feedback_ratings

  def generate_ratings_renderer(options={}, inputs={})
    @rnd = build_renderer('/page', '/feedback/ratings/ratings', options, inputs)
  end

  before(:each) do
    @test_class = TestTarget.new
    @test_class.id = 100

    @test_inputs = { :input => [:content_identifier, ['TestTarget', @test_class.id]] }
    @test_target_hash = FeedbackEndUserRating.target_hash('TestTarget', @test_class.id)

    @session = {}
    @feedback_session = Feedback::RatingsRenderer::FeedbackSession.new @session
    @feedback_session.add( @test_target_hash, 'TestTarget', @test_class.id )
  end

  it "should be able to add a rating with logged in user" do
    mock_user

    options = {}
    inputs = {}
    @rnd = generate_ratings_renderer(options, inputs)
    @rnd.should_receive(:create_feedback_session).and_return(@feedback_session)
    @rnd.should_receive(:ajax?).any_number_of_times.and_return(true)
    @rnd.should_receive(:ajax_url).and_return('/test')

    assert_difference 'FeedbackEndUserRating.count', 1 do
      renderer_post @rnd, {:target => @test_target_hash, :rating => 5}

      @feedback_rating = FeedbackRating.find(:last)
      @feedback_rating.should_not be_nil
      @feedback_rating.target_type.should == 'TestTarget'
      @feedback_rating.target_id.should == 100
      @feedback_rating.rating_sum.should == 5
      @feedback_rating.rating_count.should == 1

      @feedback_end_user_rating = FeedbackEndUserRating.find(:last)
      @feedback_end_user_rating.should_not be_nil
      @feedback_end_user_rating.target_type.should == 'TestTarget'
      @feedback_end_user_rating.target_id.should == 100
      @feedback_end_user_rating.rating.should == 5
    end
  end
end
