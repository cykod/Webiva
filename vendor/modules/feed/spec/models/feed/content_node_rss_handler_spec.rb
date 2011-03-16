require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"

describe Feed::ContentNodeRssHandler do

  reset_domain_tables :site_nodes, :content_nodes, :site_versions, :content_types

  it "should create the data for a content node rss feed" do
    home = SiteVersion.default.root_node.add_subpage('home')
    SiteVersion.default.root_node.add_subpage('about-us')
    SiteVersion.default.root_node.add_subpage('contact')

    @type = ContentType.create :component => 'editor', :content_name => 'Static Pages', :content_type => 'SiteNode', :title_field => 'name', :url_field => 'id', :search_results => 1, :editable => 0, :created_at => Time.now, :updated_at => Time.now
    @type.id.should_not be_nil
    ContentNode.update_all :content_type_id => @type.id

    @options = Feed::ContentNodeRssHandler::Options.new({:feed_title => 'My Static Pages', :description => 'My Description for static pages', :link_id => home.id})
    @feed = Feed::ContentNodeRssHandler.new(@options)
    data = @feed.get_feed
    data[:title].should == 'My Static Pages'
    data[:description].should == 'My Description for static pages'
    data[:link].should include('/home')

    data[:items].detect { |item| item[:link].include?('/home') && item[:title] == 'Home' }.should be_true
    data[:items].detect { |item| item[:link].include?('/about-us') && item[:title] == 'About Us' }.should be_true
    data[:items].detect { |item| item[:link].include?('/contact') && item[:title] == 'Contact' }.should be_true
  end
end
