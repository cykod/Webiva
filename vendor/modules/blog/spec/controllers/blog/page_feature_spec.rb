require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"

describe Blog::PageFeature, :type => :view do

  reset_domain_tables :blog_blogs, :blog_posts, :blog_post_revisions, :blog_posts_categories, :blog_categories, :content_nodes, :content_types, :site_nodes

  before(:each) do
    @blog = Blog::BlogBlog.create(:name => 'Test Blog', :content_filter => 'full_html')
    @category = @blog.blog_categories.create :name => 'new'
    @post = @blog.blog_posts.new :title => 'Test Post', :body => 'Test Body'

    @post.publish(5.minutes.ago)
    @post.save
    @feature = build_feature('/blog/page_feature')

    @detail_page_node = SiteVersion.default.root.add_subpage('detail')
    @list_page_node = SiteVersion.default.root.add_subpage('list')
  end

  it "should render a entry list paragraph" do
    pages,entries = @blog.paginate_posts(1,10)

    @output = @feature.blog_entry_list_feature(:blog => @blog,
					       :entries => entries,
					       :detail_page => @detail_page_node.node_path,
					       :list_page => @list_page_node.node_path,
					       :pages => pages,
					       :type => nil,
					       :identifier => nil
					       )

    @output.should include( @post.title )
  end

  it "should render a entry detail paragraph" do
    @output = @feature.blog_entry_detail_feature(:entry => @post,
						 :blog => @blog,
						 :detail_page => @detail_page_node.node_path,
						 :list_page => @list_page_node.node_path
						 )

    @output.should include( @post.title )
  end

  it "should render a categories paragraph" do
    @categories = @blog.blog_categories.find(:all)

    @output = @feature.blog_categories_feature(:detail_page => @detail_page_node.node_path,
					       :list_page => @list_page_node.node_path,
					       :categories => @categories,
					       :selected_category => @category.name,
					       :blog_id => @blog.id
					       )

    @output.should include( @category.name )
    @output.should include( @post.title )
  end

  it "should render a preview paragraph" do
    @post.preview = 'Preview Test'

    @output = @feature.blog_post_preview_feature(:entry => @post
						 )

    @output.should include( 'Preview Test' )
  end
end
