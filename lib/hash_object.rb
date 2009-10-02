# Copyright (C) 2009 Pascal Rettig.

class HashObject
  def initialize(hsh = {},defaults = {}) 
    @hsh = HashWithIndifferentAccess.new(defaults.merge(hsh || {}))
  end
  
  def id 
    @hsh[:id]
  end
  
  def method_missing(arg, *args)
    return @hsh[arg.to_sym] if @hsh[arg.to_sym]
    raise "Invalid Accessor: #{arg}"
  end

  def []=(key,value)
    @hsh[key] = value
  end
  
  def [](key)
    @hsh[key]
  end
  
  def to_h
    @hsh
  end
  
  def to_hash
    @hsh
  end 
end
