require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../../../spec/spec_helper"

require  File.expand_path(File.dirname(__FILE__)) + '/../../../../media_test_helper'

describe Media::Players::Video::FlvPlayer do

  include MediaTestHelper

  it "should require no options to be set" do
    opts = {}
    options = Media::Players::Video::FlvPlayer::Options.new opts
    options.valid?.should be_true
  end

  describe "player abilities" do

    before(:each) do
      opts = {}
      @options = mock :width => 100,
	              :height => 100,
	              :autoplay => true,
	              :loop => true,
	              :media_file => mock(:url => 'test.flv', :full_url => 'http://test.dev/test.flv'),
	              :handler_options => Media::Players::Video::FlvPlayer::Options.new(opts)
    end

    it "should be able to render a player" do
      player = Media::Players::Video::FlvPlayer.new @options
      player.should_receive(:swf_url).and_return('test.swf')
      player.render_player('test_div').should include(@options.media_file.full_url)
    end

    it "should respond to media video handler" do
      Media::Players::Video::FlvPlayer.respond_to?('media_video_handler_info').should be_true
    end

  end
end
