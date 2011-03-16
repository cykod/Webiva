require File.dirname(__FILE__) + "/../../spec_helper"


describe Editor::ContentRenderer, :type => :controller do
  controller_name :page
  
  integrate_views

  describe "Recent Content Paragraph" do 
    def generate_renderer(data = {})
      build_renderer('/page','/editor/content/recent_content',data,{})
    end

    it "should render the recent content paragraph" do
      ContentNode.should_receive(:find).once.with(:all, :conditions => {:published => true}, :limit => 10, :order => 'created_at DESC').and_return([])
      @rnd = generate_renderer
      @rnd.should_render_feature("recent_content")
      renderer_get @rnd
    end

    it "should render the recent content paragraph for specific types" do
      ContentNode.should_receive(:find).once.with(:all, :conditions => {:content_type_id => [4, 5], :published => true}, :limit => 10, :order => 'created_at DESC').and_return([])
      @rnd = generate_renderer :content_type_ids => [4, 5]
      @rnd.should_render_feature("recent_content")
      renderer_get @rnd
    end

    it "should render the recent content paragraph by most recently updated" do
      ContentNode.should_receive(:find).once.with(:all, :conditions => {:published => true}, :limit => 5, :order => 'updated_at DESC').and_return([])
      @rnd = generate_renderer :order_by => 'updated', :count => 5
      @rnd.should_render_feature("recent_content")
      renderer_get @rnd
    end
  end
end
