
class UserSubscriptionEntrySegmentField < UserSegment::FieldHandler

  def self.user_segment_fields_handler_info
    {
      :name => 'User Subscription Fields',
      :domain_model_class => UserSubscriptionEntry
    }
  end

  class UserSubscriptionType < UserSegment::FieldType
    register_operation :is, [['User Subscription', :model, {:class => UserSubscription}]]

    def self.is(cls, group_field, field, id)
      cls.scoped(:conditions => ["#{field} = ?", id])
    end
  end

  register_field :num_subscriptions, UserSegment::CoreType::CountType, :field => :end_user_id, :name => '# Subscriptions', :display_method => 'count', :sort_method => 'count', :sortable => true
  register_field :user_subscription_id, UserSubscriptionEntrySegmentField::UserSubscriptionType, :name => 'User Subscription', :display_field => :user_subscription

  def self.sort_scope(order_by, direction)
    info = UserSegment::FieldHandler.sortable_fields[order_by.to_sym]
    sort_method = info[:sort_method]
    field = info[:field]
    UserSubscriptionEntry.scoped(:select => "end_user_id, #{sort_method}(#{field}) as #{field}_#{sort_method}", :group => :end_user_id, :order => "#{field}_#{sort_method} #{direction}")
  end

  def self.field_heading(field)
    self.user_segment_fields[field][:name]
  end

  def self.get_handler_data(ids, fields)
    UserSubscriptionEntry.find(:all, :include => :user_subscription, :conditions => {:end_user_id => ids}).group_by(&:end_user_id)
  end

  def self.field_output(user, handler_data, field)
    UserSegment::FieldType.field_output(user, handler_data, field)
  end
end
