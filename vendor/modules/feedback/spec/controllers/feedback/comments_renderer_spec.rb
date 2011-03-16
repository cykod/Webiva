require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"

require  File.expand_path(File.dirname(__FILE__)) + '/../../feedback_test_helper'

describe Feedback::CommentsRenderer, :type => :controller do

  include FeedbackTestHelper

  controller_name :page

  integrate_views

  reset_domain_tables :comments, :end_users

  def generate_comments_renderer(options={}, inputs={})
    @rnd = build_renderer('/page', '/feedback/comments/comments', options, inputs)
  end

  before(:each) do
    @test_class = TestTarget.new
    @test_class.id = 100

    @test_inputs = { :input => [:content_identifier, ['TestTarget', @test_class.id]] }
  end

  it "should be able to add a comment with logged in user" do
    mock_user

    options = {}
    inputs = @test_inputs
    @rnd = generate_comments_renderer(options, inputs)

    assert_difference 'Comment.count', 1 do
      renderer_post @rnd, {"comment_#{@rnd.paragraph.id}" => { :comment => 'Test Comment' }}

      @comment = Comment.find(:last)
      @comment.should_not be_nil
      @comment.comment.should == 'Test Comment'
      @comment.target_type.should == 'TestTarget'
      @comment.target_id.should == @test_class.id
    end
  end

  it "should be able to add a comment with logged in user and set user name" do
    mock_user
    @myself.first_name = nil
    @myself.last_name = nil
    @myself.full_name = nil
    @myself.save

    options = {}
    inputs = @test_inputs
    @rnd = generate_comments_renderer(options, inputs)

    assert_difference 'Comment.count', 1 do
      renderer_post @rnd, {"comment_#{@rnd.paragraph.id}" => { :name => 'Test Name', :comment => 'Test Comment' }}

      @comment = Comment.find(:last)
      @comment.should_not be_nil
      @comment.comment.should == 'Test Comment'
      @comment.target_type.should == 'TestTarget'
      @comment.target_id.should == @test_class.id
    end

    @myself.reload
    @myself.first_name.should == 'Test'
    @myself.last_name.should == 'Name'
    @myself.full_name.should == 'Test Name'
  end

  it "should be able to add a comment with logged in user when linked to a page" do
    mock_user

    options = { :linked_to_type => 'page' }
    inputs = {}
    @rnd = generate_comments_renderer(options, inputs)

    @page_revision = PageRevision.new
    @rnd.paragraph.should_receive(:page_revision).any_number_of_times.and_return(@page_revision)
    @page_revision.should_receive(:revision_container_type).and_return('TestTarget')
    @page_revision.should_receive(:revision_container_id).and_return(15)

    assert_difference 'Comment.count', 1 do
      renderer_post @rnd, {"comment_#{@rnd.paragraph.id}" => { :comment => 'Test Comment' }}

      @comment = Comment.find(:last)
      @comment.should_not be_nil
      @comment.comment.should == 'Test Comment'
      @comment.target_type.should == 'TestTarget'
      @comment.target_id.should == 15
    end
  end

  it "should be able to add a comment with not logged in user" do
    options = { :allowed_to_post => 'all' }
    inputs = @test_inputs
    @rnd = generate_comments_renderer(options, inputs)

    assert_difference 'Comment.count', 1 do
      renderer_post @rnd, {"comment_#{@rnd.paragraph.id}" => { :name => 'Test User', :comment => 'Test Comment' }}

      @comment = Comment.find(:last)
      @comment.should_not be_nil
      @comment.comment.should == 'Test Comment'
      @comment.name.should == 'Test User'
      @comment.target_type.should == 'TestTarget'
      @comment.target_id.should == @test_class.id
    end
  end

  it "should be able to add a comment with not logged in user when linked to a page" do
    options = { :allowed_to_post => 'all', :linked_to_type => 'page' }
    inputs = {}
    @rnd = generate_comments_renderer(options, inputs)

    @page_revision = PageRevision.new
    @rnd.paragraph.should_receive(:page_revision).any_number_of_times.and_return(@page_revision)
    @page_revision.should_receive(:revision_container_type).and_return('TestTarget')
    @page_revision.should_receive(:revision_container_id).and_return(15)

    assert_difference 'Comment.count', 1 do
      renderer_post @rnd, {"comment_#{@rnd.paragraph.id}" => { :name => 'Test User', :comment => 'Test Comment' }}

      @comment = Comment.find(:last)
      @comment.should_not be_nil
      @comment.comment.should == 'Test Comment'
      @comment.name.should == 'Test User'
      @comment.target_type.should == 'TestTarget'
      @comment.target_id.should == 15
      @comment.posted_at.should_not be_nil
    end
  end
end
