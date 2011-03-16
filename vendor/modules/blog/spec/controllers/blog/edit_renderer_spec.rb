require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"


describe Blog::EditRenderer, :type => :controller do
  controller_name :page
  
  integrate_views

  def generate_page_renderer(paragraph, options={}, inputs={})
    @rnd = build_renderer('/page', '/blog/edit/' + paragraph, options, inputs)
  end

  reset_domain_tables :blog_blogs, :blog_posts, :blog_post_revisions, :blog_posts_categories, :blog_categories, :content_nodes, :content_types, :site_nodes

  before(:each) do
    mock_editor
    @blog = Blog::BlogBlog.create(:name => 'Test Blog', :content_filter => 'full_html', :is_user_blog => true)
    @category = @blog.blog_categories.create :name => 'new'
    @post = @blog.blog_posts.new :title => 'Test Post', :body => 'Test Body'
    @post.publish 5.minutes.ago
    @post.save
    @blog.target = @post
    @blog.save

    @edit_page_node = SiteVersion.default.root.add_subpage('edit')
    @list_page_node = SiteVersion.default.root.add_subpage('list')
  end

  it "should be able to list user posts" do
    inputs = { :input => [:container, @post] }
    options = {:auto_create => true, :blog_name => '%s Blog',:edit_page_id => @edit_page_node.id}
    @rnd = generate_page_renderer('list', options, inputs)
    @rnd.should_receive(:blog_edit_list_feature).and_return('')
    renderer_get @rnd
  end

  it "should be able to render the write page" do
    inputs = { :target => [:container, @post] }
    options = {:list_page_id => @list_page_node.id}
    @rnd = generate_page_renderer('write', options, inputs)
    @rnd.should_receive(:blog_edit_write_feature).and_return('')
    renderer_get @rnd
  end

end
