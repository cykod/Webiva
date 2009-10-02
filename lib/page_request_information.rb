# Copyright (C) 2009 Pascal Rettig.

class PageRequestInformation
  
  def initialize
    @node = nil
    @path = nil
    @module = nil
    @info_set = false
  end
  
  def set_information(node,path,request)
    @info_set = true
    @node = node
    @path = path
    @request = request
  end
  
  def unset?
    return @info_set == false
  end
  
  attr_reader :path
  attr_reader :node
  attr_reader :request
  
end
