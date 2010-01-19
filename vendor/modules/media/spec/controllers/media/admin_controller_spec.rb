require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"

require  File.expand_path(File.dirname(__FILE__)) + '/../../media_test_helper'

describe Media::AdminController do

  include MediaTestHelper

  reset_domain_tables :configurations, :site_modules

  before(:each) do
    mod = SiteModule.activate_module(Domain.find(DomainModel.active_domain_id),'media')
    mod.update_attributes(:status => 'active')
  end

  it "should be able to set audio and video handlers" do
    mock_editor
    opts = {}
    @options = Media::AdminController::Options.new opts
    video_handler = @options.media_video_handlers[0][1]
    audio_handler = @options.media_audio_handlers[0][1]
    post 'options', :path => [], :options => { :media_video_handler => video_handler, :media_audio_handler => audio_handler }
    response.should redirect_to(:controller => '/modules')
  end

  it "should be able to set default video options" do
    mock_editor

    opts = {}
    @options = Media::AdminController::Options.new opts
    video_handler = @options.media_video_handlers[0][1]
    audio_handler = @options.media_audio_handlers[0][1]
    post 'options', :path => [], :options => { :media_video_handler => video_handler, :media_audio_handler => audio_handler }

    post 'video_options', :path => [], :options => {:width => 100, :height => 100}
    response.should redirect_to(:action => 'options')
  end

  it "should be able to set default audio options" do
    mock_editor

    opts = {}
    @options = Media::AdminController::Options.new opts
    video_handler = @options.media_video_handlers[0][1]
    audio_handler = @options.media_audio_handlers[0][1]
    post 'options', :path => [], :options => { :media_video_handler => video_handler, :media_audio_handler => audio_handler }

    post 'audio_options', :path => [], :options => {:autoplay => true}
    response.should redirect_to(:action => 'options')
  end

end
