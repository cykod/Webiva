require File.dirname(__FILE__) + "/../spec_helper"
require 'treetop'

describe UserSegmentOptionParser do

  def parse(text)
    parser = UserSegmentOptionParser.new
    if data = parser.parse(text)
      data.eval
    else
      raise parser.inspect
      nil
    end
  end

  it "should be able to parse operations to and array" do
    code = <<-CODE
    created.since(1, "days")
    CODE
    parse(code).should == [[nil, {:field => 'created', :operation => 'since', :arguments => [1, "days"], :child => nil}]]

    code = <<-CODE
    created_at.since_ago(1, "days")
    CODE
    parse(code).should == [[nil, {:field => 'created_at', :operation => 'since_ago', :arguments => [1, "days"], :child => nil}]]

    code = <<-CODE
    created_at2.since_ago8(1, "days")
    CODE
    parse(code).should == [[nil, {:field => 'created_at2', :operation => 'since_ago8', :arguments => [1, "days"], :child => nil}]]

    code = <<-CODE
    test.contains("")
    CODE
    parse(code).should == [[nil, {:field => 'test', :operation => 'contains', :arguments => [''], :child => nil}]]

    code = <<-CODE
    test.contains(true, false)
    CODE
    parse(code).should == [[nil, {:field => 'test', :operation => 'contains', :arguments => [true, false], :child => nil}]]

    code = 'test.contains("days\"", 1)'
    parse(code).should == [[nil, {:field => 'test', :operation => 'contains', :arguments => ['days"', 1], :child => nil}]]

    code = <<-CODE
    test.contains('1.1')
    CODE
    parse(code).should == [[nil, {:field => 'test', :operation => 'contains', :arguments => ['1.1'], :child => nil}]]

    code = "test.contains('1.1\\'')"
    parse(code).should == [[nil, {:field => 'test', :operation => 'contains', :arguments => ["1.1'"], :child => nil}]]

    code = <<-CODE
    test.contains(1.1)
    CODE
    parse(code).should == [[nil, {:field => 'test', :operation => 'contains', :arguments => [1.1], :child => nil}]]

    code = <<-CODE
    test.contains(1.0)
    CODE
    parse(code).should == [[nil, {:field => 'test', :operation => 'contains', :arguments => [1.0], :child => nil}]]

    code = <<-CODE
    test.contains(.1)
    CODE
    parse(code).should == [[nil, {:field => 'test', :operation => 'contains', :arguments => [0.1], :child => nil}]]
  end

  it "should be able to not an operation" do
    code = <<-CODE
    Not created.since(1, "days")
    CODE
    parse(code).should == [['not', {:field => 'created', :operation => 'since', :arguments => [1, "days"], :child => nil}]]
  end

  it "should be able to chain operations" do
    code = <<-CODE
    created.since(1, "days").registered.is(true)
    CODE
    parse(code).should == [[nil, {:field => 'created', :operation => 'since', :arguments => [1, "days"], :child => {:field => 'registered', :operation => 'is', :arguments => [true], :child => nil}}]]

    code = <<-CODE
    created.since(1, "days").registered.is(true).logged_in.is(false)
    CODE
    parse(code).should == [[nil, {:field => 'created', :operation => 'since', :arguments => [1, "days"], :child => {:field => 'registered', :operation => 'is', :arguments => [true], :child => {:field => 'logged_in', :operation => 'is', :arguments => [false], :child => nil}}}]]

    code = <<-CODE
    NOT created.since(1, "days").registered.is(true).logged_in.is(false)
    CODE
    parse(code).should == [['not', {:field => 'created', :operation => 'since', :arguments => [1, "days"], :child => {:field => 'registered', :operation => 'is', :arguments => [true], :child => {:field => 'logged_in', :operation => 'is', :arguments => [false], :child => nil}}}]]
  end

  it "should be able to or operations" do
    code = <<-CODE
    created.since(1, "days") + registered.is(true)
    CODE
    parse(code).should == [[nil, {:field => 'created', :operation => 'since', :arguments => [1, "days"], :child => nil}, {:field => 'registered', :operation => 'is', :arguments => [true], :child => nil}]]

    code = <<-CODE
    created.since(1, "days") + registered.is(true) + test.is('good')
    CODE
    parse(code).should == [[nil, {:field => 'created', :operation => 'since', :arguments => [1, "days"], :child => nil}, {:field => 'registered', :operation => 'is', :arguments => [true], :child => nil}, {:field => 'test', :operation => 'is', :arguments => ['good'], :child => nil}]]
  end

  it "should be able to and operations" do
    code = <<-CODE
    created.since(1, "days")
    registered.is(true)
    CODE
    parse(code).should == [
      [nil, {:field => 'created', :operation => 'since', :arguments => [1, "days"], :child => nil}],
      [nil, {:field => 'registered', :operation => 'is', :arguments => [true], :child => nil}]
    ]
  end

  it "should parse a complaticated set of operations" do
    code = <<-CODE
    created.since(1  , "days").born.before('yesterday')+   registered.is( true )
    registered.is( true )
    not    test.is( false ) + product.purchased( 'computer' ).created.since(       1, 'days'  )
    CODE
    parse(code).should == [
      [nil, {:field => 'created', :operation => 'since', :arguments => [1, "days"], :child => {:field => 'born', :operation => 'before', :arguments => ['yesterday'], :child => nil}}, {:field => 'registered', :operation => 'is', :arguments => [true], :child => nil}],
      [nil, {:field => 'registered', :operation => 'is', :arguments => [true], :child => nil}],
      ['not', {:field => 'test', :operation => 'is', :arguments => [false], :child => nil}, {:field => 'product', :operation => 'purchased', :arguments => ['computer'], :child => {:field => 'created', :operation => 'since', :arguments => [1, 'days'], :child => nil}}]
    ]
  end

  it "should parse array values as arguments" do
    code = <<-CODE
    user_level.is([4,5,6])
    CODE
    parse(code).should == [[nil, {:field => 'user_level', :operation => 'is', :arguments => [[4,5,6]], :child => nil}]]

    code = <<-CODE
    user_level.is("days", [4,5,6], true, [1,2], 5)
    CODE
    parse(code).should == [[nil, {:field => 'user_level', :operation => 'is', :arguments => ["days", [4,5,6], true, [1,2], 5], :child => nil}]]
  end
end
