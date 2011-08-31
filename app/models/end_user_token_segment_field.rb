
class EndUserTokenSegmentField < UserSegment::FieldHandler

  def self.user_segment_fields_handler_info
    {
      :name => 'User Access Fields',
      :domain_model_class => EndUserToken
    }
  end

  class AccessTokenType < UserSegment::FieldType
    register_operation :is, [['Access Token', :model, {:class => AccessToken}]]

    def self.is(cls, group_field, token_id)
      cls.scoped(:conditions => ["#{field[0]} = ?", token_id])
    end
  end

  register_field :access_token, EndUserTokenSegmentField::AccessTokenType, :field => :access_token_id, :name => 'User Access: Token'
  register_field :num_tokens, UserSegment::CoreType::CountType, :field => :end_user_id, :name => '# Access Tokens', :display_method => 'count', :sort_method => 'count', :sortable => true
  register_field :access_valid_until, UserSegment::CoreType::DateTimeType, :field => :valid_until, :name => 'User Access: Valid Until', :sortable => true
  register_field :access_valid_at, UserSegment::CoreType::DateTimeType, :field => :valid_at, :name => 'User Access: Valid At', :sortable => true

  def self.sort_scope(order_by, direction)
     info = UserSegment::FieldHandler.sortable_fields[order_by.to_sym]

    if order_by.to_sym == :num_tokens
      sort_method = info[:sort_method]
      field = info[:field]
      EndUserToken.scoped(:select => "end_user_id, #{sort_method}(#{field}) as #{field}_#{sort_method}", :group => :end_user_id, :order => "#{field}_#{sort_method} #{direction}")
    else
      field = self.user_segment_fields[order_by.to_sym][:field]
      EndUserToken.scoped :order => "#{field} #{direction}"
    end
  end

  def self.field_heading(field)
    self.user_segment_fields[field][:name]
  end

  def self.get_handler_data(ids, fields)
    EndUserToken.find(:all, :conditions => {:end_user_id => ids}, :include => :access_token).group_by(&:end_user_id)
  end

  def self.field_output(user, handler_data, field)
    UserSegment::FieldType.field_output(user, handler_data, field)
  end
end
