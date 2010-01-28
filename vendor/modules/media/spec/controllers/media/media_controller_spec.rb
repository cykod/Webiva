require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"

require  File.expand_path(File.dirname(__FILE__)) + '/../../media_test_helper'

describe Media::MediaController do

  include MediaTestHelper

  reset_domain_tables :configurations, :site_modules

  before(:each) do
    mod = SiteModule.activate_module(Domain.find(DomainModel.active_domain_id),'media')
    mod.update_attributes(:status => 'active')
    
    @options = Media::AdminController::module_options
    @options.media_video_handler = @options.media_video_handlers[0][1]
    @options.media_audio_handler = @options.media_audio_handlers[0][1]
    Configuration.set_config_model(@options)
  end

  it "should require a video file" do
    opts = {}
    @media_options = Media::MediaController::VideoOptions.new opts
    @media_options.valid?.should be_false
    @media_options.errors[:media_file_id].should_not be_nil
  end

  it "should require a audio file" do
    opts = {}
    @media_options = Media::MediaController::AudioOptions.new opts
    @media_options.valid?.should be_false
    @media_options.errors[:media_file_id].should_not be_nil
  end

  it "should be able to use default video options" do
    @media_options = Media::AdminController.video_options
    @media_options.handler_data = {:volume => 9}
    Configuration.set_config_model(@media_options)

    opts = {}
    @new_options = Media::MediaController::VideoOptions.new opts
    @new_options.handler_options.volume.should == 9
  end

  it "should be able to use default audio options" do
    @media_options = Media::AdminController.audio_options
    @media_options.handler_data = {:volume => 9}
    Configuration.set_config_model(@media_options)

    opts = {}
    @new_options = Media::MediaController::AudioOptions.new opts
    @new_options.handler_options.volume.should == 9
  end

end
