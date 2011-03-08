require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"

describe Feed::GenericFeedEater do

  it "should ouput a hash from xml" do
    @eater = Feed::GenericFeedEater.new 'http://fake-url.dev/', 'xml'
    @eater.should_receive(:get).once.and_return('<?xml version="1.0" encoding="UTF-8"?><items><item><name>Test</name><id>1</id></item><item><name>Test2</name><id>2</id></item></items>')
    @eater.parse

    @eater.output.should == {"items"=>{"item"=>[{"name"=>"Test", "id"=>"1"}, {"name"=>"Test2", "id"=>"2"}]}}
  end

  it "should ouput a hash from json" do
    @eater = Feed::GenericFeedEater.new 'http://fake-url.dev/', 'json'
    @eater.should_receive(:get).once.and_return('{"items":{"item":[{"name":"Test","id":"1"},{"name":"Test2","id":"2"}]}}')
    @eater.parse

    @eater.output.should == {"items"=>{"item"=>[{"name"=>"Test", "id"=>"1"}, {"name"=>"Test2", "id"=>"2"}]}}
  end
end
