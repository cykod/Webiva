# Copyright (C) 2009 Pascal Rettig.

class HashObject
  def initialize(hsh = {},defaults = {})
    @hsh = defaults.symbolize_keys.merge((hsh || {}).symbolize_keys)
  end
  
  def id 
    @hsh[:id]
  end
  
  def method_missing(arg, *args)
    return @hsh[arg.to_sym] if @hsh[arg.to_sym]
    raise "Invalid Accessor: #{arg}"
  end

  def []=(key,value)
    @hsh[key.to_sym] = value
  end
  
  def [](key)
    @hsh[key.to_sym]
  end
  
  def to_h
    @hsh.symbolize_keys
  end
  
  def to_hash
    to_h
  end 
end
