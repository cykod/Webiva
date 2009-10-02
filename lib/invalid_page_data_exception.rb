# Copyright (C) 2009 Pascal Rettig.

class InvalidPageDataException < RuntimeError
  attr_reader :error_str

  def initialize(err)
     @error_str = err
  end
  
  def to_s
    @error_str.to_s
  end

end