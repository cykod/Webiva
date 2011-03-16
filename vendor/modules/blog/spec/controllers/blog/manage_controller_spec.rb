require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"

describe Blog::ManageController do

  reset_domain_tables :blog_blogs, :blog_posts, :blog_post_revisions, :blog_posts_categories, :blog_categories, :content_nodes, :content_types, :mail_templates

  before(:each) do
    mock_editor
    @blog = Blog::BlogBlog.create(:name => 'Test Blog', :content_filter => 'full_html')
    @category = @blog.blog_categories.create :name => 'Test Category'
    @post = @blog.blog_posts.new(:title => 'Test Post',:body => 'Test Body')
    @post.save
  end

  it "should be able to render index page" do
    get 'index', :path => [@blog.id]
  end

  it "should handle post table list" do
    # Test all the permutations of an active table
    controller.should handle_active_table(:post_table) do |args|
      args[:path] = [@blog.id]
      post 'post_table', args
    end
  end

  it "should be able to render index page" do
    get 'generate_mail', :path => [@blog.id]
  end

  it "should handle generate post table list" do
    # Test all the permutations of an active table
    controller.should handle_active_table(:generate_post_table) do |args|
      args[:path] = [@blog.id]
      post 'display_generate_post_table', args
    end
  end

  it "should be able to delete a blog post" do
    assert_difference 'Blog::BlogPost.count', -1 do
      post 'post_table', :path => [@blog.id], :table_action => 'delete', :post => {@post.id.to_s => 1}
    end
  end

  it "should be able to publish a blog post" do
    @post.status.should == 'draft'
    @post.published_at.should be_nil

    assert_difference 'Blog::BlogPost.count', 0 do
      post 'post_table', :path => [@blog.id], :table_action => 'publish', :post => {@post.id.to_s => 1}
    end

    @post.reload
    @post.status.should == 'published'
    @post.published_at.should_not be_nil
  end

  it "should be able to render generate_mail" do
    get 'generate_mail', :path => [@blog.id]
  end

  it "should be able to render generate_mail_generate" do
    get 'generate_mail_generate', :path => [@blog.id], :post_id => @post.id, :opts => {:align => 'left', :header => 'above'}
  end

  it "should be able to render generate_categories" do
    get 'generate_categories', :path => [@blog.id]
  end

  it "should be able to create a mail template from a post" do
    assert_difference 'MailTemplate.count', 1 do
      post 'mail_template', :path => [@blog.id, @post.id]
    end

    @template = MailTemplate.find(:last)
    response.should redirect_to(:controller => '/mail_manager', :action => 'edit_template', :path => @template.id)
  end

  it "should be able to render create a post" do
    get 'post', :path => [@blog.id]
  end

  it "should be able to render edit a post" do
    get 'post', :path => [@blog.id, @post.id]
  end

  it "should be able to create a post" do
    assert_difference 'Blog::BlogPost.count', 1 do
      post 'post', :path => [@blog.id], :entry => {:title => 'New Blog Title', :body => 'New Blog Body'}, :update_entry => {:status => 'draft'}
    end

    response.should redirect_to(:action => 'index', :path => @blog.id)

    @new_post = Blog::BlogPost.find :last
    @new_post.published_at.should be_nil
    @new_post.status.should == 'draft'
  end

  it "should be able to create a post and publish it" do
    Blog::BlogBlog.should_receive(:find).any_number_of_times.and_return(@blog)
    @blog.should_receive(:send_pingbacks)

    assert_difference 'Blog::BlogPost.count', 1 do
      post 'post', :path => [@blog.id], :entry => {:title => 'New Blog Title', :body => 'New Blog Body'}, :update_entry => {:status => 'publish_now'}
    end

    response.should redirect_to(:action => 'index', :path => @blog.id)

    @new_post = Blog::BlogPost.find :last
    @new_post.status.should == 'published'
    @new_post.published_at.should_not be_nil
  end

  it "should be able to create a post and publish it" do
    Blog::BlogBlog.should_receive(:find).any_number_of_times.and_return(@blog)
    @blog.should_receive(:send_pingbacks)

    published_at = 1.hour.ago

    assert_difference 'Blog::BlogPost.count', 1 do
      post 'post', :path => [@blog.id], :entry => {:title => 'New Blog Title', :body => 'New Blog Body', :published_at => published_at}, :update_entry => {:status => 'post_date'}
    end

    response.should redirect_to(:action => 'index', :path => @blog.id)

    @new_post = Blog::BlogPost.find :last
    @new_post.status.should == 'published'
    @new_post.published_at.to_i.should == published_at.to_i
  end

  it "should be able to edit a post" do
    assert_difference 'Blog::BlogPost.count', 0 do
      post 'post', :path => [@blog.id, @post.id], :entry => {:title => 'New Blog Title', :body => 'Test Body'}, :update_entry => {:status => 'draft'}
    end

    response.should redirect_to(:action => 'index', :path => @blog.id)

    @post.reload
    @post.title.should == 'New Blog Title'
  end

  it "should be able to edit a post and add categories" do
    assert_difference 'Blog::BlogPost.count', 0 do
      post 'post', :path => [@blog.id, @post.id], :entry => {:title => 'New Blog Title'}, :update_entry => {:status => 'draft'}, :categories => [@category.id]
    end

    response.should redirect_to(:action => 'index', :path => @blog.id)

    @post.reload
    @post.title.should == 'New Blog Title'

    @post_category = Blog::BlogPostsCategory.find_by_blog_post_id_and_blog_category_id @post.id, @category.id
    @post_category.should_not be_nil
  end

  it "should be able to edit a post and delete categories" do
    @post.set_categories! [@category.id]
    @post.reload
    @post_category = Blog::BlogPostsCategory.find_by_blog_post_id_and_blog_category_id @post.id, @category.id
    @post_category.should_not be_nil

    assert_difference 'Blog::BlogPost.count', 0 do
      post 'post', :path => [@blog.id, @post.id], :entry => {:title => 'New Blog Title'}, :update_entry => {:status => 'draft'}, :categories => []
    end

    response.should redirect_to(:action => 'index', :path => @blog.id)

    @post.reload
    @post.title.should == 'New Blog Title'

    @post_category = Blog::BlogPostsCategory.find_by_blog_post_id_and_blog_category_id @post.id, @category.id
    @post_category.should be_nil
  end

  it "should be able to render delete a blog" do
    get 'delete', :path => [@blog.id]
  end

  it "should be able to delete a blog" do
    assert_difference 'Blog::BlogBlog.count', -1 do
      post 'delete', :path => [@blog.id], :destroy => 'yes'
    end

    response.should redirect_to(:controller => '/content', :action => 'index')
  end

  it "should be able to add category" do
    assert_difference 'Blog::BlogCategory.count', 1 do
      post 'add_category', :path => [@blog.id], :name => 'New Category'
    end

    @new_category = Blog::BlogCategory.find :last
    @new_category.name.should == 'New Category'
  end

  it "should not be able to add same category" do
    assert_difference 'Blog::BlogCategory.count', 0 do
      post 'add_category', :path => [@blog.id], :name => 'Test Category'
    end
  end

  it "should not be able to render edit a blog" do
    get 'configure', :path => [@blog.id]
  end

  it "should not be able to edit a blog" do
    assert_difference 'Blog::BlogBlog.count', 0 do
      post 'configure', :path => [@blog.id], :blog => {:name => 'New Blog Name'}
    end

    response.should redirect_to(:action => 'index', :path => @blog.id)

    @blog.reload
    @blog.name.should == 'New Blog Name'
  end

  it "should not be able to render add_tags" do
    get 'add_tags', :path => [@blog.id], :existing_tags => ''
  end

  it "should be able to render list page" do
    get 'list'
  end

  it "should handle blog table list" do
    # Test all the permutations of an active table
    controller.should handle_active_table(:blog_list_table) do |args|
      post 'display_blog_list_table', args
    end
  end

  it "should be able to delete a user blog" do
    @user_blog = Blog::BlogBlog.create(:name => 'Test Blog', :content_filter => 'full_html', :is_user_blog => true)
    assert_difference 'Blog::BlogBlog.count', -1 do
      post 'display_blog_list_table', :table_action => 'delete', :blog => {@user_blog.id.to_s => @user_blog.id.to_s}
    end
  end
end
