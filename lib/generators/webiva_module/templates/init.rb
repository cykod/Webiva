# Copyright (C) 2009 Pascal Rettig.

load_paths.each do |path|
  Dependencies.load_once_paths.delete(path)
end


