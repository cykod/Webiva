# Copyright (C) 2009 Pascal Rettig.


# Base options class for publication field options
class Content::PublicationFieldOptions < HashModel #:nodoc:
  attributes :field_format => nil, :preset => nil, :dynamic => nil, :order => nil, :options => nil, :required => false, :filter => nil,
  :filter_weight => 1.0 ,:filter_options => [], :fuzzy_filter => 'a'

  float_options :filter_weight

  has_options :filter, [['Off',nil],['Filter','filter'],['Fuzzy Filter','fuzzy']]

  boolean_options :required
end
