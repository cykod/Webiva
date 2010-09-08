require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"


describe Blog::PageRenderer, :type => :controller do
  controller_name :page
  
  integrate_views

  def generate_page_renderer(paragraph, options={}, inputs={})
    @rnd = build_renderer('/page', '/blog/page/' + paragraph, options, inputs)
  end

  reset_domain_tables :blog_blogs, :blog_posts, :blog_post_revisions, :blog_posts_categories, :blog_categories, :content_nodes, :content_types, :site_nodes

  before(:each) do
    mock_editor
    @blog = Blog::BlogBlog.create(:name => 'Test Blog', :content_filter => 'full_html')
    @category = @blog.blog_categories.create :name => 'new'
    @post = @blog.blog_posts.new  :title => 'Test Post', :body => 'Test Body'
    @post.save
  end

  it "should be able to list posts" do
    @detail_page_node = SiteVersion.default.root.add_subpage('detail')
    options = {:blog_id => @blog.id, :detail_page => @detail_page_node.id}
    @rnd = generate_page_renderer('entry_list', options)

    Blog::BlogBlog.should_receive(:find_by_id).with(@blog.id).and_return(@blog)

    renderer_get @rnd
  end

  it "should be able to list posts from blog_id page connection" do
    options = {}
    inputs = { :blog => [:blog_id, @blog.id] }
    @rnd = generate_page_renderer('entry_list', options, inputs)

    Blog::BlogBlog.should_receive(:find_by_id).with(@blog.id).and_return(@blog)

    renderer_get @rnd
  end

  it "should be able to list posts from target page connection" do
    @blog.is_user_blog = true
    @blog.target = @post
    @blog.save.should be_true

    options = { :blog_target_id => @blog.blog_target_id}
    inputs = { :blog => [:container, @post] }
    @rnd = generate_page_renderer('entry_list', options, inputs)

    Blog::BlogBlog.should_receive(:find_by_target_type_and_target_id).with(@post.class.to_s, @post.id,:conditions => { :blog_target_id => @blog.blog_target_id } ).and_return(@blog)

    renderer_get @rnd
  end

  it "should be able to list posts with list_type category" do
    options = {:blog_id => @blog.id}
    inputs = { :type => [:list_type, 'category'], :identifier => [:list_type_identifier, 'new2'] }
    @rnd = generate_page_renderer('entry_list', options, inputs)
    @rnd.should_receive(:set_page_connection).with(:category,'new2')

    Blog::BlogBlog.should_receive(:find_by_id).with(@blog.id).and_return(@blog)

    renderer_get @rnd
  end

  it "should be able to list posts with list_type tag" do
    options = {:blog_id => @blog.id}
    inputs = { :type => [:list_type, 'tag'], :identifier => [:list_type_identifier, 'yourit'] }
    @rnd = generate_page_renderer('entry_list', options, inputs)

    Blog::BlogBlog.should_receive(:find_by_id).with(@blog.id).and_return(@blog)

    renderer_get @rnd
  end

  it "should be able to list posts with list_type archive" do
    options = {:blog_id => @blog.id}
    inputs = { :type => [:list_type, 'archive'], :identifier => [:list_type_identifier, 'January2010'] }
    @rnd = generate_page_renderer('entry_list', options, inputs)

    Blog::BlogBlog.should_receive(:find_by_id).with(@blog.id).and_return(@blog)

    renderer_get @rnd
  end

  it "should be able to display a post by permalink" do
    list_page_node = SiteVersion.default.root.add_subpage('list')
    options = {:blog_id => @blog.id, :list_page_id => list_page_node.id}
    inputs = { :input => [:post_permalink, @post.permalink] }
    @rnd = generate_page_renderer('entry_detail', options, inputs)

    Blog::BlogBlog.should_receive(:find_by_id).with(@blog.id).and_return(@blog)
    @blog.should_receive(:find_post_by_permalink).with(@post.permalink).and_return(@post)

    @rnd.should_receive(:set_page_connection).with(:comments_ok, true)
    @rnd.should_receive(:set_page_connection).with(:content_id, ['Blog::BlogPost',@post.id])
    @rnd.should_receive(:set_page_connection).with(:post, @post.id)

    renderer_get @rnd
  end

  it "should be able to display a post by permalink using blog target" do
    @blog.is_user_blog = true
    @blog.target = @post
    @blog.save.should be_true

    options = { :blog_target_id => @blog.blog_target_id }
    inputs = { :input => [:post_permalink, @post.permalink], :blog => [:container, @post] }
    @rnd = generate_page_renderer('entry_detail', options, inputs)

    Blog::BlogBlog.should_receive(:find_by_target_type_and_target_id).with(@post.class.to_s, @post.id,:conditions => { :blog_target_id => @blog.blog_target_id }).and_return(@blog)
    @blog.should_receive(:find_post_by_permalink).with(@post.permalink).and_return(@post)

    renderer_get @rnd
  end

  it "should be able to display a post by permalink using blog id" do
    options = {}
    inputs = { :input => [:post_permalink, @post.permalink], :blog => [:blog_id, @blog.id] }
    @rnd = generate_page_renderer('entry_detail', options, inputs)

    Blog::BlogBlog.should_receive(:find_by_id).with(@blog.id).and_return(@blog)
    @blog.should_receive(:find_post_by_permalink).with(@post.permalink).and_return(@post)

    renderer_get @rnd
  end

  it "should be able to list categories for a blog" do
    @list_page_node = SiteVersion.default.root.add_subpage('list')
    @detail_page_node = SiteVersion.default.root.add_subpage('detail')
    options = {:blog_id => @blog.id, :list_page_id => @list_page_node.id, :detail_page_id => @detail_page_node.id}
    @rnd = generate_page_renderer('categories', options)
    renderer_get @rnd
  end
end
