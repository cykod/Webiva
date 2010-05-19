
class UserSegment < DomainModel

  has_many :user_segment_caches, :order => 'position', :dependent => :delete_all, :class_name => 'UserSegmentCache'
  serialize :segment_options
  serialize :fields

  validates_presence_of :name
  validates_presence_of :segment_options

  def initialize(opts={})
    super
    self.fields = [] unless self.fields
  end

  def ready?; self.status == 'finished'; end

  def validate
    self.errors.add(:segment_options_text, 'is invalid') if self.segment_options_text && self.segment_options.nil?
  end

  def operations
    return @operations if @operations
    @operations = UserSegment::Operations.new
    @operations.operations = self.segment_options if self.segment_options
    @operations
  end

  def segment_options_text=(text)
    text = text.gsub("\r", '').strip
    @should_refresh = self.segment_options_text != text
    self.write_attribute :segment_options_text, text
    @operations = UserSegment::Operations.new
    @operations.parse text
    self.segment_options = @operations.valid? ? self.operations.to_a : nil
    text
  end

  def should_refresh?
    @should_refresh
  end

  def refresh
    if self.status == 'new' || self.ready?
      self.status = 'refreshing'
      self.save

      if EndUser.count < 50000
        self.cache_ids
      else
        self.run_worker(:cache_ids)
      end
    end
  end

  def cache_ids(opts={})
    self.status = 'calculating'
    self.save

    self.user_segment_caches.delete_all

    self.order_by = 'created_at DESC' unless self.order_by
    ids = EndUser.find(:all, :select => 'id', :conditions => {:id => self.operations.end_user_ids, :client_user_id => nil}, :order => self.order_by).collect &:id

    num_segements = (self.operations.end_user_ids.length / UserSegmentCache::SIZE)
    num_segements = num_segements + 1 if (self.operations.end_user_ids.length % UserSegmentCache::SIZE) > 0

    (0..num_segements-1).each do |idx|
      start = idx * UserSegmentCache::SIZE
      self.user_segment_caches.create :id_list => ids[start..start+UserSegmentCache::SIZE-1], :position => idx
    end

    self.status = 'finished'
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

  def paginate(page=1, args={})
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

  def search(args={})
    args = args.clone.symbolize_keys!
    
    offset = args.delete(:offset).to_i
    limit = args.delete(:limit).to_i
    limit = 20 if limit <= 0

    cache_offset = offset % UserSegmentCache::SIZE

    if args[:scope].nil?
      args[:scope] = EndUser.scoped(:conditions => args.delete(:conditions), :joins => args.delete(:joins))
      args[:end_user_field] = :id
    end

    ids = []
    ((offset / UserSegmentCache::SIZE).to_i..self.user_segment_caches.length-1).each do |position|
      cache = self.user_segment_caches.find_by_position(position)
      cache_offset, cache_ids = cache.search(cache_offset, args.merge(:limit => limit-ids.length))
      ids = ids + cache_ids
      offset = UserSegmentCache::SIZE * position + cache_offset
      cache_offset = 0
      break if ids.length >= limit
    end

    args.delete(:scope)
    args.delete(:end_user_field)
    users = EndUser.find(:all, args.merge(:conditions => {:id => ids}))
    return [offset, users]
  end

  def before_create
    self.status = 'new'
  end

  def self.fields_options
    [['Source', 'source'], ['Date of Birth', 'dob'], ['Gender', 'gender'], ['Created', 'created_at'], ['Registered', 'registered_at'], ['User Class', 'user_class']]
  end

  def self.order_by_options
    [['Created Desc', 'created_at DESC'], ['Created Asc', 'created_at'], ['Email', 'email']]
  end
end

