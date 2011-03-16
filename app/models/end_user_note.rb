
class EndUserNote < DomainModel
  belongs_to :end_user
  belongs_to :admin_user, :class_name => 'EndUser'

  validates_presence_of :note
  validates_presence_of :end_user_id

end
