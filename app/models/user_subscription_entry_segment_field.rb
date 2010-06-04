
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

  register_field :user_subscription_id, UserSubscriptionEntrySegmentField::UserSubscriptionType, :name => 'User Subscription'

  def self.field_heading(field)
    self.user_segment_fields[field][:name]
  end

  def self.get_handler_data(ids, fields)
    UserSubscriptionEntry.find(:all, :include => :user_subscription, :conditions => {:end_user_id => ids}).group_by(&:end_user_id)
  end

  def self.field_output(user, handler_data, field)
    return nil unless handler_data[user.id]

    if field == :user_subscription_id
      handler_data[user.id].collect{ |s| s.user_subscription.name }.join(', ')
    else
      nil
    end
  end
end
