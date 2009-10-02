ActiveRecord::Base.class_eval do
  include Taggable::Acts::AsTaggable
end
