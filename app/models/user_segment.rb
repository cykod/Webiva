
class UserSegment < DomainModel

  has_many :user_segment_caches, :order => 'created_at, id', :dependent => :destroy, :class_name => 'UserSegmentCache'
  serialize :segment_options
  serialize :fields

  validates_presence_of :name

  def operations
    return @operations if @operations
    @operations = UserSegment::Operations.new
    @operations.operations = self.segment_options if self.segment_options
    @operations
  end

  def segment_options_text=(text)
    self.write_attribute :segment_options_text, text
    @operations = UserSegment::Operations.new
    @operations.parse text
    self.segment_options = @operations.valid? ? self.operations.to_a : nil
    text
  end

  def cache_ids
    self.user_segment_caches.delete_all

    self.order_by = 'created_at DESC' unless self.order_by
    ids = EndUser.find(:all, :select => 'id', :conditions => {:id => self.operations.end_user_ids}, :order => self.order_by)

    num_segements = (self.operations.end_user_ids.length / 1000)
    num_segements = num_segements + 1 if (self.operations.end_user_ids.length % 1000) > 0

    (0..num_segements-1).each do |idx|
      start = idx * 1000
      self.user_segment_caches.create :id_list => ids[start..start+999]
    end

    self.last_ran_at = Time.now
    self.last_count = ids.length
    self.save
  end

  def end_user_ids
    return @end_user_ids if @end_user_ids
    @end_user_ids = []
    self.user_segment_caches.each do |segement|
      @end_user_ids = @end_user_ids + segement.id_list
    end
    @end_user_ids
  end

  def each(opts={}, &block)
    self.user_segment_caches.each do |segement|
      segement.each opts, &block
    end
  end

  def each_with_index(opts={}, &block)
    idx = 0
    self.user_segment_caches.each do |segement|
      idx = segement.each_with_index idx, opts, &block
    end
  end

  def find(opts={}, &block)
    self.user_segment_caches.each do |segement|
      user = segement.find opts, &block
      return user if user
    end
  end
end

