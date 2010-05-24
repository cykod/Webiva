
class EndUserCacheSegmentField < UserSegment::FieldHandler

  def self.user_segment_fields_handler_info
    {
      :name => 'End User Cache Segment Fields',
      :domain_model_class => EndUserCache
    }
  end

  register_field :cache, UserSegment::CoreType::MatchType, :field => :data, :name => 'User Caches: Cache'

end
