# Copyright (C) 2009 Pascal Rettig.

require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"


describe Blog::AddBlogWizard do


  reset_domain_tables :blog_blogs, :blog_posts, :blog_post_revisions, :blog_posts_categories, :blog_categories, :content_nodes, :content_types, :site_nodes, :page_paragraphs,:page_revisions

  before(:each) do
    @blog = Blog::BlogBlog.create(:name => 'Test Blog',:content_filter => 'full_html')
  end

  it "should add the blog to site" do
    root_node = SiteVersion.default.root_node.add_subpage('tester')
    wizard = Blog::AddBlogWizard.new(
                                     :blog_id => @blog.id,
                                     :add_to_id => root_node.id,
                                     :add_to_subpage => 'blog',
                                     :detail_page_url => 'myview',
                                     :number_of_dummy_posts => 0
                                     )
    wizard.run_wizard

    SiteNode.find_by_node_path('/tester/blog').should_not be_nil
    
  end

end
