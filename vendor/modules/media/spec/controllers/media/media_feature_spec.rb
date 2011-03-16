require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"

require  File.expand_path(File.dirname(__FILE__)) + '/../../media_test_helper'

describe Media::MediaFeature, :type => :view do
  include MediaTestHelper

  reset_domain_tables :configurations

  before(:each) do

    mod = SiteModule.activate_module(Domain.find(DomainModel.active_domain_id),'media')
    mod.update_attributes(:status => 'active')
    
    opts = {}
    @options = Media::AdminController.module_options
    @options.media_video_handler = @options.media_video_handlers[0][1]
    @options.media_audio_handler = @options.media_audio_handlers[0][1]
    Configuration.set_config_model(@options)

    @media = mock :url => 'test.flv', :full_url => 'http://test.dev/test.flv'

    @video_options = Media::MediaController::VideoOptions.new opts
    @audio_options = Media::MediaController::AudioOptions.new opts
    @swf_options = Media::MediaController::SwfOptions.new opts

    @feature = build_feature('/media/media_feature')
    @paragraph = mock :id => 1, :language => 'en'
  end

  describe "Media Feature" do
    it "should display a video player" do
      @feature.should_receive(:paragraph).any_number_of_times.and_return(@paragraph)
      @video_options.should_receive(:media_file).at_least(1).and_return(@media)
      @output = @feature.media_media_video_feature({:options => @video_options})
      @output.should include(@media.full_url)
    end

    it "should display an audio player" do
      @feature.should_receive(:paragraph).any_number_of_times.and_return(@paragraph)
      @feature.should_receive(:require_js).and_return('')
      @audio_options.should_receive(:media_file).at_least(1).and_return(@media)
      @output = @feature.media_media_audio_feature({:options => @audio_options})
      @output.should include(@media.full_url)
    end

    it "should display a swf" do
      @feature.should_receive(:paragraph).any_number_of_times.and_return(@paragraph)
      @swf_options.should_receive(:swf_url).and_return('test.swf')
      @output = @feature.media_media_swf_feature({:options => @swf_options})
      @output.should include('test.swf')
    end
  end
end
