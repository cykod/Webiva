# Copyright (C) 2009 Pascal Rettig.


# Base options class for publication field options
class Content::PublicationFieldOptions < HashModel
  attributes :field_format => nil, :preset => nil, :dynamic => nil, :order => nil, :options => nil, :required => false

  boolean_options :required
end
