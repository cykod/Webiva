require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../../../spec/spec_helper"

require  File.expand_path(File.dirname(__FILE__)) + '/../../../../media_test_helper'

describe Media::Players::Audio::WordPressAudioPlayer do

  include MediaTestHelper

  it "should require no options to be set" do
    opts = {}
    options = Media::Players::Audio::WordPressAudioPlayer::Options.new opts
    options.valid?.should be_true
  end

  describe "player abilities" do

    before(:each) do
      opts = {}
      @options = mock :autoplay => true,
	              :loop => true,
	              :media_file => mock(:url => 'test.mp3', :full_url => 'http://test.dev/test.mp3'),
	              :handler_options => Media::Players::Audio::WordPressAudioPlayer::Options.new(opts)
    end

    it "should be able to render a player" do
      player = Media::Players::Audio::WordPressAudioPlayer.new @options
      player.render_player('test_div').should include(@options.media_file.full_url)
    end

    it "should respond to media audio handler" do
      Media::Players::Audio::WordPressAudioPlayer.respond_to?('media_audio_handler_info').should be_true
    end

  end
end
