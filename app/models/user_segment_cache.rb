
=begin rdoc
A user segment cache is used to store the list of user ids.

Should not be used directly. Instead use UserSegment methods.

=end
class UserSegmentCache < DomainModel
  SIZE = 25000
  DEFAULT_BATCH_SIZE = 1000

  belongs_to :user_segment

  serialize :id_list

  validates_presence_of :user_segment_id

  def before_create #:nodoc:
    self.created_at = Time.now unless self.created_at
  end

  def fetch_users(opts={})
    ids = opts[:offset] && opts[:limit] ? self.id_list[opts[:offset]..opts[:offset]+opts[:limit]-1] : self.id_list
    return [] if ! ids || ids.empty?
    users_by_id = EndUser.find(:all, :conditions => {:id => ids}, :include => opts[:include]).index_by(&:id)
    ids.map { |id| users_by_id[id] }.compact
  end

  def search(offset=0, opts={})
    opts = opts.clone.symbolize_keys!
    opts.delete(:offset)
    opts.delete(:include)
    limit = opts.delete(:limit) || 20
    batch_size = opts.delete(:batch_size) || DEFAULT_BATCH_SIZE
    num_chunks = (self.id_list.size / batch_size).to_i
    num_chunks = num_chunks.succ if (self.id_list.length % batch_size) > 0

    base_scope = opts.delete(:scope) || EndUserCache
    end_user_field = opts.delete(:end_user_field) || :end_user_id

    ids = []
    ((offset/batch_size).to_i..num_chunks-1).each do |chunk|
      sub_list = self.id_list[offset..(offset+batch_size-1)]
      scope = base_scope.scoped(:select => end_user_field.to_s, :conditions => {end_user_field.to_sym => sub_list})
      users_by_id = scope.find(:all).index_by(&end_user_field.to_sym)
      ids = ids + sub_list.map { |id| users_by_id[id] ? id : nil }.compact unless users_by_id.empty?
      offset = offset + batch_size
      break if ids.length > limit
    end

    has_more = ids.length > limit
    ids = ids[0..limit-1] if has_more
    offset = ids.size > 0 ? self.id_list.index(ids[-1]) : self.id_list.length - 1
    [offset, ids]
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
      users = nil
      GC.start
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
