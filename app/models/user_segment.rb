
class UserSegment < DomainModel

  has_many :user_segment_caches, :order => 'position', :dependent => :destroy, :class_name => 'UserSegmentCache'
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
    ids = EndUser.find(:all, :select => 'id', :conditions => {:id => self.operations.end_user_ids}, :order => self.order_by).collect &:id

    num_segements = (self.operations.end_user_ids.length / UserSegmentCache::SIZE)
    num_segements = num_segements + 1 if (self.operations.end_user_ids.length % UserSegmentCache::SIZE) > 0

    (0..num_segements-1).each do |idx|
      start = idx * UserSegmentCache::SIZE
      self.user_segment_caches.create :id_list => ids[start..start+UserSegmentCache::SIZE-1], :position => idx
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

  def collect(opts={}, &block)
    data = []
    self.user_segment_caches.each do |segement|
      data = data + segement.collect(opts, &block)
    end
    data
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

  def paginate(page,args = {})
    args = args.clone.symbolize_keys!
    window_size =args.delete(:window) || 2
    
    page_size = args.delete(:per_page).to_i
    page_size = 20 if page_size <= 0

    total_count = self.last_count
    pages = (total_count.to_f / (page_size || 10)).ceil
    pages = 1 if pages < 1
    page = (page ? page.to_i : 1).clamp(1,pages)
      
    offset = (page-1) * page_size

    position = (offset / UserSegmentCache::SIZE).to_i

    cache = self.user_segment_caches.find_by_position(position)
    items = cache ? cache.fetch_users(:offset => (offset % UserSegmentCache::SIZE), :limit => page_size) : []

    [ { :pages => pages, 
        :page => page, 
        :window_size => window_size, 
        :total => total_count,
        :per_page => page_size,
        :first => offset+1,
        :last => offset + items.length,
        :count => items.length
      }, items ]
  end

  def search(offset=0, args={})
    args = args.clone.symbolize_keys!
    
    page_size = args.delete(:per_page).to_i
    page_size = 20 if page_size <= 0

    cache_offset = offset % UserSegmentCache::SIZE

    ids = []
    ((offset / UserSegmentCache::SIZE).to_i..self.user_segment_caches.length-1).each do |position|
      cache = self.user_segment_caches.find_by_position(position)
      cache_offset, cache_ids = cache.search(cache_offset, args.merge(:limit => page_size-ids.length))
      ids = ids + cache_ids
      offset = UserSegmentCache::SIZE * position + cache_offset
      cache_offset = 0
      break if ids.length >= page_size
    end

    args.delete(:conditions)
    args.delete(:joins)
    users = EndUser.find(:all, args.merge(:conditions => {:id => ids}))
    return [offset, users]
  end
end

