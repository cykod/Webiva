require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"

describe Blog::AdminController do

  reset_domain_tables :blog_blogs, :blog_posts, :blog_post_revisions, :blog_posts_categories, :blog_categories, :content_nodes, :content_types

  it "should be able to create a blog" do
    mock_editor

    assert_difference 'Blog::BlogBlog.count', 1 do
      post 'create', :path => [], :blog => { :name => 'Test Blog', :content_filter => 'full_html' }
      @blog = Blog::BlogBlog.find(:last)
      response.should redirect_to(:controller => '/blog/manage', :path => [@blog.id])
    end
  end

end
