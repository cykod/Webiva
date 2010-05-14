
class UserSegmentCache < DomainModel
  belongs_to :user_segment

  serialize :id_list

  validates_presence_of :user_segment_id

  def before_create
    self.created_at = Time.now unless self.created_at
  end

  def end_users
    @end_users ||= EndUser.find(:all, :conditions => {:id => self.id_list})
  end

  def each
    self.end_users.each { |user| yield user }
  end

  def each_with_index(idx=0)
    self.end_users.each { |user| yield user, idx; idx = idx.succ }
    idx
  end

  def find
    self.end_users.find { |user| yield user }
  end
end
