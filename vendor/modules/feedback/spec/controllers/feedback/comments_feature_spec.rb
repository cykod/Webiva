require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"

require  File.expand_path(File.dirname(__FILE__)) + '/../../feedback_test_helper'

describe Feedback::CommentsFeature, :type => :view do

  include FeedbackTestHelper

  reset_domain_tables :comments, :end_users

  it 'Initial test data validation' do
    @user = create_end_user
    @user.save.should be_true

    @test_class = TestTarget.new
    @test_class.id = 100

    @comment = Comment.new :end_user => @user, :comment => 'Test Comment', :target_type => 'TestTarget', :target_id => @test_class.id
    @comment.save.should be_true
  end

  describe "Comments Feature" do

    before(:each) do
    end

    it "should display list of comments" do
      @user = create_end_user
      @user.save

      @test_class = TestTarget.new
      @test_class.id = 100

      @test_comment = Comment.create :end_user => @user, :comment => 'Test Comment', :target_type => 'TestTarget', :target_id => @test_class.id
      @test_comment.id.should_not be_nil

      @feature = build_feature('/feedback/comments_feature')

      @options = Feedback::CommentsController::CommentsOptions.new({})

      @comment = Comment.new
      @comments = Comment.find(:all, :limit => 10)

      @feature.should_receive(:myself).and_return(@user)

      @output = @feature.comments_page_comments_feature({:comment => @comment, :comments => @comments, :paragraph_id => 1, :options => @options})
      @output.should include( @test_comment.comment )
    end

  end
end
