require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"

describe Blog::BlogPostsCategory do

  reset_domain_tables :blog_blogs, :blog_posts, :blog_post_revisions, :blog_posts_categories, :blog_categories, :content_nodes, :content_types

  it "should be able to set blog post categories" do
    @blog = Blog::BlogBlog.create :name => 'Test Blog', :content_filter => 'full_html'
    @category = @blog.blog_categories.create :name => 'Test Category'
    @post = @blog.blog_posts.new :title => 'Test Post', :body => 'Testerama',:author => 'Anonymous'
    @post.save

    assert_difference 'Blog::BlogPostsCategory.count', 1 do
      @post.set_categories! [@category.id]
    end

    @post_category = Blog::BlogPostsCategory.find_by_blog_post_id_and_blog_category_id @post.id, @category.id
    @post_category.should_not be_nil
  end

end
