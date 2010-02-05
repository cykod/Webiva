require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"

describe Blog::BlogPostRevision do

  reset_domain_tables :blog_blogs, :blog_posts, :blog_post_revisions, :blog_posts_categories, :blog_categories, :content_nodes, :content_types

  before(:each) do
    @blog = Blog::BlogBlog.create :name => 'Test Blog', :content_filter => 'full_html'
    @category = @blog.blog_categories.create :name => 'Test Category'
    @post = @blog.blog_posts.new
    @rev = Blog::BlogPostRevision.new
  end

  it "revision should not be valid" do
    @rev.should_not be_valid
  end

  it "should be creatable with a title, body and blog_post_id" do
    @post.save.should be_true
    @rev.title = 'Title'
    @rev.body = 'Body'
    @rev.blog_post_id = @post.id
    @rev.should be_valid

    assert_difference 'Blog::BlogPostRevision.count', 1 do
      @rev.save.should be_true
    end

    @rev.id.should_not be_nil
    @post.blog_post_revision_id.should be_nil
    @post.blog_post_revisions.include?(@rev).should be_true
  end

  it "should become active revision when saved with save_revision!" do
    @post.save.should be_true
    @rev.title = 'Title'
    @rev.body = 'Body'
    @rev.blog_post_id = @post.id
    @rev.should be_valid

    assert_difference 'Blog::BlogPostRevision.count', 1 do
      @post.save_revision! @rev
    end

    @rev.id.should_not be_nil
    @post.blog_post_revision_id.should == @rev.id
    @post.blog_post_revisions.include?(@rev).should be_true
  end
end
