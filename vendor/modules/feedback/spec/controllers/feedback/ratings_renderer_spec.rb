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

      @feedback_session.size.should == 1
    end
  end

  it "should only keep track of the last MAX_SESSION_RATINGS targets with ratings seen" do
    mock_user

    options = {}
    inputs = {}
    @rnd = generate_ratings_renderer(options, inputs)
    @rnd.should_receive(:create_feedback_session).and_return(@feedback_session)
    @rnd.should_receive(:ajax?).any_number_of_times.and_return(true)
    @rnd.should_receive(:ajax_url).and_return('/test')

    target_hash = nil
    target_id = nil
    (1..100).each do |target_id|
      target_hash = FeedbackEndUserRating.target_hash('TestTarget', target_id)
      @feedback_session.add( target_hash, 'TestTarget', target_id )
    end

    assert_difference 'FeedbackEndUserRating.count', 1 do
      renderer_post @rnd, {:target => target_hash, :rating => 5}

      @feedback_rating = FeedbackRating.find(:last)
      @feedback_rating.should_not be_nil
      @feedback_rating.target_type.should == 'TestTarget'
      @feedback_rating.target_id.should == target_id
      @feedback_rating.rating_sum.should == 5
      @feedback_rating.rating_count.should == 1

      @feedback_end_user_rating = FeedbackEndUserRating.find(:last)
      @feedback_end_user_rating.should_not be_nil
      @feedback_end_user_rating.target_type.should == 'TestTarget'
      @feedback_end_user_rating.target_id.should == target_id
      @feedback_end_user_rating.rating.should == 5

      @feedback_session.size.should == Feedback::RatingsRenderer::FeedbackSession::MAX_SESSION_RATINGS
    end
  end

  it "should keep computing the correct average rating" do
    sum = 0
    (2..10).each do |cnt|
      rating = 1 + rand(5)
      sum += rating
      @feedback_end_user_rating = FeedbackEndUserRating.new :target_type => 'TestTarget', :target_id => @test_class.id, :end_user_id => cnt, :rating => rating
      @feedback_end_user_rating.save.should be_true
      @feedback_end_user_rating.rating.should == rating

      @feedback_rating = FeedbackRating.with_target('TestTarget', @test_class.id).find(:first)
      @feedback_rating.should_not be_nil
      @feedback_rating.rating_count.should == (cnt-1)
      @feedback_rating.rating_sum.should == sum
    end

    mock_user

    options = {}
    inputs = {}
    @rnd = generate_ratings_renderer(options, inputs)
    @rnd.should_receive(:create_feedback_session).and_return(@feedback_session)
    @rnd.should_receive(:ajax?).any_number_of_times.and_return(true)
    @rnd.should_receive(:ajax_url).and_return('/test')

    rating = 1 + rand(5)
    sum += rating
    cnt = 10

    assert_difference 'FeedbackEndUserRating.count', 1 do
      renderer_post @rnd, {:target => @test_target_hash, :rating => rating}

      @feedback_rating = FeedbackRating.with_target('TestTarget', @test_class.id).find(:first)
      @feedback_rating.should_not be_nil
      @feedback_rating.target_type.should == 'TestTarget'
      @feedback_rating.target_id.should == @test_class.id
      @feedback_rating.rating_count.should == cnt
      @feedback_rating.rating_sum.should == sum

      @feedback_end_user_rating = FeedbackEndUserRating.with_target('TestTarget', @test_class.id).find(:last)
      @feedback_end_user_rating.should_not be_nil
      @feedback_end_user_rating.target_type.should == 'TestTarget'
      @feedback_end_user_rating.target_id.should == @test_class.id
      @feedback_end_user_rating.rating.should == rating
    end
  end

  it "should keep computing the correct average rating even when a user updates his rating" do
    mock_user

    rating = 1 + rand(5)
    sum = rating

    @mock_user_rating = FeedbackEndUserRating.new :target_type => 'TestTarget', :target_id => @test_class.id, :end_user_id => @myself.id, :rating => rating
    @mock_user_rating.save.should be_true
    @mock_user_rating.rating.should == rating

    (2..10).each do |cnt|
      rating = 1 + rand(5)
      sum += rating
      @feedback_end_user_rating = FeedbackEndUserRating.new :target_type => 'TestTarget', :target_id => @test_class.id, :end_user_id => cnt, :rating => rating
      @feedback_end_user_rating.save.should be_true
      @feedback_end_user_rating.rating.should == rating

      @feedback_rating = FeedbackRating.with_target('TestTarget', @test_class.id).find(:first)
      @feedback_rating.should_not be_nil
      @feedback_rating.rating_count.should == cnt
      @feedback_rating.rating_sum.should == sum
    end

    options = {}
    inputs = {}
    @rnd = generate_ratings_renderer(options, inputs)
    @rnd.should_receive(:create_feedback_session).and_return(@feedback_session)
    @rnd.should_receive(:ajax?).any_number_of_times.and_return(true)
    @rnd.should_receive(:ajax_url).and_return('/test')

    rating = 1 + rand(5)
    sum += (rating - @mock_user_rating.rating)
    cnt = 10

    assert_difference 'FeedbackEndUserRating.count', 0 do
      renderer_post @rnd, {:target => @test_target_hash, :rating => rating}

      @feedback_rating = FeedbackRating.with_target('TestTarget', @test_class.id).find(:first)
      @feedback_rating.should_not be_nil
      @feedback_rating.target_type.should == 'TestTarget'
      @feedback_rating.target_id.should == @test_class.id
      @feedback_rating.rating_count.should == cnt
      @feedback_rating.rating_sum.should == sum

      @feedback_end_user_rating = FeedbackEndUserRating.with_target('TestTarget', @test_class.id).find_by_end_user_id(@myself.id)
      @feedback_end_user_rating.should_not be_nil
      @feedback_end_user_rating.target_type.should == 'TestTarget'
      @feedback_end_user_rating.target_id.should == @test_class.id
      @feedback_end_user_rating.rating.should == rating
    end
  end

  it "should not add a new rating if a user tries to add a rating for an unknown target_hash" do
    mock_user

    options = {}
    inputs = {}
    @rnd = generate_ratings_renderer(options, inputs)
    @rnd.should_receive(:create_feedback_session).and_return(@feedback_session)
    @rnd.should_receive(:ajax?).once.and_return(true)

    target_hash = nil
    target_id = nil
    (1..50).each do |target_id|
      target_hash = FeedbackEndUserRating.target_hash('TestTarget', target_id)
      @feedback_session.add( target_hash, 'TestTarget', target_id )
    end

    assert_difference 'FeedbackEndUserRating.count', 0 do
      renderer_post @rnd, {:target => @test_target_hash, :rating => 5}

      @feedback_rating = FeedbackRating.with_target('TestTarget', @test_class.id).find(:last)
      @feedback_rating.should be_nil

      @feedback_end_user_rating = FeedbackEndUserRating.with_target('TestTarget', @test_class.id).find_by_end_user_id(@myself.id)
      @feedback_end_user_rating.should be_nil
    end
  end

  it "should not add a new rating if a user is not logged in" do
    options = {}
    inputs = {}
    @rnd = generate_ratings_renderer(options, inputs)
    @rnd.should_receive(:create_feedback_session).and_return(@feedback_session)
    @rnd.should_receive(:ajax?).once.and_return(true)

    assert_difference 'FeedbackEndUserRating.count', 0 do
      renderer_post @rnd, {:target => @test_target_hash, :rating => 5}

      @feedback_end_user_rating = FeedbackEndUserRating.with_target('TestTarget', @test_class.id).find(:last)
      @feedback_end_user_rating.should be_nil

      @feedback_rating = FeedbackRating.with_target('TestTarget', @test_class.id).find(:last)
      @feedback_rating.should be_nil
    end
  end

  it "should be able to add a rating with non logged in user" do
    options = { :allowed_to_rate => 'all' }
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

      @feedback_session.size.should == 1
    end
  end

  it "should not be able to add an invalid rating" do
    mock_user

    options = { :max_stars => 3 }
    inputs = {}
    @rnd = generate_ratings_renderer(options, inputs)
    @rnd.should_receive(:create_feedback_session).and_return(@feedback_session)
    @rnd.should_receive(:ajax?).once.and_return(true)

    assert_difference 'FeedbackEndUserRating.count', 0 do
      renderer_post @rnd, {:target => @test_target_hash, :rating => 5}

      @feedback_rating = FeedbackRating.with_target('TestTarget', @test_class.id).find(:last)
      @feedback_rating.should be_nil

      @feedback_end_user_rating = FeedbackEndUserRating.with_target('TestTarget', @test_class.id).find_by_end_user_id(@myself.id)
      @feedback_end_user_rating.should be_nil
    end
  end
end
