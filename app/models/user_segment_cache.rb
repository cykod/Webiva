
class UserSegmentCache < DomainModel
  SIZE = 25000
  DEFAULT_BATCH_SIZE = 1000

  belongs_to :user_segment

  serialize :id_list

  validates_presence_of :user_segment_id

  def before_create
    self.created_at = Time.now unless self.created_at
  end

  def fetch_users(opts={})
    ids = opts[:offset] && opts[:limit] ? self.id_list[opts[:offset]..opts[:offset]+opts[:limit]-1] : self.id_list
    users_by_id = EndUser.find(:all, :conditions => {:id => ids}).index_by(&:id)
    ids.map { |id| users_by_id[id] }.compact
  end

  def find_in_batches(opts={})
    limit = opts[:batch_size] || DEFAULT_BATCH_SIZE
    offset = 0
    num_chunks = (self.id_list.size / limit).to_i
    num_chunks = num_chunks.succ if (self.id_list.length % limit) > 0
    (1..num_chunks).each do |chunk|
      users = self.fetch_users(:offset => offset, :limit => limit)
      offset = offset + limit
      yield users
    end
  end

  def each(opts={})
    self.find_in_batches(opts) { |users| users.each { |user| yield user } }
  end

  def collect(opts={})
    data = []
    self.find_in_batches(opts) { |users| data = data + users.collect { |user| yield user } }
    data
  end

  def each_with_index(idx=0, opts={})
    self.find_in_batches(opts) { |users| users.each { |user| yield user, idx; idx = idx.succ } }
    idx
  end

  def find(opts={})
    self.find_in_batches(opts) do |users|
      user = users.find { |user| yield user }
      return user if user
    end
    nil
  end
end
