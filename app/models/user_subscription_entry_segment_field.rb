
class UserSubscriptionEntrySegmentField < UserSegment::FieldHandler

  def self.user_segment_fields_handler_info
    {
      :name => 'User Subscription Fields',
      :domain_model_class => UserSubscriptionEntry
    }
  end

  class UserSubscriptionType < UserSegment::FieldType
    register_operation :is, [['User Subscription', :model, {:class => UserSubscription}]]

    def self.is(cls, field, id)
      cls.scoped(:conditions => ["#{field} = ?", id])
    end
  end

  register_field :user_subscription_id, UserSubscriptionEntrySegmentField::UserSubscriptionType, :name => 'User Subscription'
end
