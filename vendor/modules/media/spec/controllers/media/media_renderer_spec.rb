require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"

require  File.expand_path(File.dirname(__FILE__)) + '/../../media_test_helper'

describe Media::MediaRenderer, :type => :controller do
  include MediaTestHelper
  controller_name :page

  integrate_views

  reset_domain_tables :configurations

  before(:each) do

    mod = SiteModule.activate_module(Domain.find(DomainModel.active_domain_id),'media')
    mod.update_attributes(:status => 'active')

    opts = {}
    @options = Media::AdminController.module_options
    @options.media_video_handler = @options.media_video_handlers[0][1]
    @options.media_audio_handler = @options.media_audio_handlers[0][1]
    Configuration.set_config_model(@options)

    @video_options = Media::MediaController::VideoOptions.new opts

    @audio_options = Media::MediaController::AudioOptions.new opts
  end

  describe "Media Render" do
    def generate_page_renderer(paragraph, options={}, inputs={})
      @rnd = build_renderer('/page', '/media/media/' + paragraph, options, inputs)
    end

    it "should be able render a video paragraph" do
      @rnd = generate_page_renderer('video')
      @rnd.should_render_feature('media_media_video')
      
      @rnd.should_receive(:paragraph_options).and_return(@video_options)

      renderer_get @rnd
    end

    it "should be able render a audio paragraph" do
      @rnd = generate_page_renderer('audio')
      @rnd.should_render_feature('media_media_audio')
      
      @rnd.should_receive(:paragraph_options).and_return(@audio_options)

      renderer_get @rnd
    end

    it "should be able render a swf paragraph" do
      @rnd = generate_page_renderer('swf')
      @rnd.should_render_feature('media_media_swf')
      
      renderer_get @rnd
    end
  end
end
