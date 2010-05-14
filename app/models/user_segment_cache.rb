
class UserSegmentCache < DomainModel
  belongs_to :user_segment

  serialize :id_list

  validates_presence_of :user_segment_id

  def before_create
    self.created_at = Time.now unless self.created_at
  end

  def end_users(opts={})
    return @end_users if @end_users
    users_by_id = EndUser.find(:all, :conditions => {:id => self.id_list}).index_by(&:id)
    @end_users = self.id_list.map { |id| users_by_id[id] }.compact
  end

  def each(opts={})
    self.end_users(opts).each { |user| yield user }
  end

  def each_with_index(idx=0, opts={})
    self.end_users(opts).each { |user| yield user, idx; idx = idx.succ }
    idx
  end

  def find(opts={})
    self.end_users(opts).find { |user| yield user }
  end
end
