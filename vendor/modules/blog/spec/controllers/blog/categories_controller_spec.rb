require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"

describe Blog::CategoriesController do

  reset_domain_tables :blog_blogs, :blog_posts, :blog_post_revisions, :blog_posts_categories, :blog_categories, :content_nodes, :content_types

  before(:each) do
    mock_editor
    @blog = Blog::BlogBlog.create(:name => 'Test Blog', :content_filter => 'full_html')
  end

  it "should be able to render index page" do
    get 'index', :path => [@blog.id]
  end

  it "should handle table list" do 
    cat = @blog.blog_categories.create(:name => 'Test Category')
    cat.id.should_not be_nil

    # Test all the permutations of an active table
    controller.should handle_active_table(:category_table) do |args|
      args[:path] = [@blog.id]
      post 'category_table', args
    end
  end

  it "should be able to create a blog category" do
    assert_difference 'Blog::BlogCategory.count', 1 do
      post 'create_category', :path => [@blog.id], :name => 'Test Category'
    end

    @cat = Blog::BlogCategory.find(:last)
    @cat.name.should == 'Test Category'
  end

  it "should be able to delete a blog category" do
    @cat = @blog.blog_categories.create(:name => 'Test Category')
    @cat.id.should_not be_nil

    assert_difference 'Blog::BlogCategory.count', -1 do
      post 'category_table', :path => [@blog.id], :table_action => 'delete', :category => {@cat.id.to_s => 1}
    end
  end
end
