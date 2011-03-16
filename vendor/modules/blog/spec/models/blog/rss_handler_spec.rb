require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"

describe Blog::RssHandler do

  reset_domain_tables :blog_blogs, :blog_posts, :blog_post_revisions, :blog_posts_categories, :blog_categories, :content_nodes, :content_types, :site_nodes

  before(:each) do
    mock_editor
    @blog = Blog::BlogBlog.create(:name => 'Test Blog', :content_filter => 'full_html')
    @category = @blog.blog_categories.create :name => 'new'
    @post = @blog.blog_posts.new  :title => 'Test Post', :body => 'Test Body'
    @post.publish 5.minutes.ago
    @post.save
    @detail_page_node = SiteVersion.default.root.add_subpage('detail')
    @rss_page_node = SiteVersion.default.root.add_subpage('rss')
    @options = Blog::RssHandler::Options.new :feed_identifier => "#{@rss_page_node.id},#{@blog.id},#{@detail_page_node.id}", :limit => 10
  end
  
  it "should create the data for an rss feed" do
    @feed = Blog::RssHandler.new(@options)
    data = @feed.get_feed
    data[:title].should == 'Test Blog'
    data[:items][0][:title].should == 'Test Post'
  end
end
