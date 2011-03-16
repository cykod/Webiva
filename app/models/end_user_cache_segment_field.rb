
class EndUserCacheSegmentField < UserSegment::FieldHandler

  def self.user_segment_fields_handler_info
    {
      :name => 'User Query Fields',
      :domain_model_class => EndUserCache
    }
  end

  register_field :cache, UserSegment::CoreType::MatchType, :field => :data, :name => 'Query', :search_only => true, :builder_name => 'Search for users with?'
end
