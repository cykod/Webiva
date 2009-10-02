# Copyright (c) 2007 John Guenin <john@guen.in>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN


ENV["RAILS_ENV"] ||= 'test'

require "#{File.dirname(__FILE__)}/../../../../config/boot.rb"
require "#{File.dirname(__FILE__)}/../../../../config/environment.rb"

require 'action_controller/test_process'
require 'test/unit'
require 'rubygems'
require 'mocha'

class XSendFileController < ActionController::Base
  attr_accessor :path, :options
    
  def initialize
    @path = __FILE__
    @options = {}
  end
  
  def index() render(:nothing => true) end
  def file() x_send_file(@path, @options) end
  def sendfile() send_file(@path, @options) end

  # do not rescue errors
  def rescue_action(e) raise end
end

class XSendFileTest < Test::Unit::TestCase
  def setup
    @controller = XSendFileController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
    
    # record plugin defaults
    @plugin_defaults = XSendFile::Plugin.options.dup
  end
  
  def teardown
    # restore plugin options to defaults
    XSendFile::Plugin.options = @plugin_defaults
  end
  
  # Quick santity check: make sure the test controller is firing properly
  def test_index
    get :index
    assert_response :success, 'Test Controller not working as expected'
  end
  
  # Make sure we get back an X-Sendfile header, and the value is key correctly
  def test_x_send_file_header
    get :file
    assert_response :success, 'Expected successful response'
    assert @response.headers.include?('X-Sendfile'), 'X-Sendfile header expected'
    assert_equal @controller.path, @response.headers['X-Sendfile'], 'X-Sendfile header value not as expected'
  end
  
  # Test setting a custom header in the x_send_file method call
  def test_custom_header_in_method
    custom_header = 'X-Custom-Method-Header'    
    @controller.options = { :header => custom_header }
    get :file
    assert_response :success, 'Expected successful response'
    assert @response.headers.include?(custom_header), 'Custom header expected when passed to method'
  end

  # Test setting a custom header globally in the plugin options
  def test_custom_header_global_option
    custom_header = 'X-Custom-Global-Header'
    XSendFile::Plugin.options[:header] = custom_header
    get :file
    assert_response :success, 'Expected successful response'
    assert @response.headers.include?(custom_header), 'Custom header expected when set as global option'
  end
  
  # Make sure a missing file raises an exception
  def test_missing_file_exception
    File.expects(:file?).with(@controller.path).returns(false)
    assert_raises(ActionController::MissingFile) do
      get :file
    end
  end
  
  # Make sure an unreadable file raises an exception
  def test_unreadable_file_exception
    File.expects(:readable?).with(@controller.path).returns(false)
    assert_raises(ActionController::MissingFile) do
      get :file
    end
  end
  
  # Test replacing send_file
  def test_replace_send_file
    # make sure we don't pre-emptively replace send_file
    get :sendfile
    assert_response :success, 'Expected successful response'
    assert !@response.headers.include?('X-Sendfile'), 'Unexpected replacement of send_file'
    
    # prepare for request #2...
    teardown and setup
    
    # replace send_file
    XSendFile::Plugin.replace_send_file!
    get :sendfile
    assert_response :success, 'Expected successful response'
    assert @response.headers.include?('X-Sendfile'), 'Expected X-Sendfile header'
  end
end