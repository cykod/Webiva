# Copyright (C) 2009 Pascal Rettig.

class DefaultsHashObject < HashObject
  def method_missing(arg, *args)
    return @hsh[arg.to_sym]
  end
end
