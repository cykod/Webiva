
class UserSegment < DomainModel

  has_many :user_segment_caches, :order => 'position', :dependent => :delete_all, :class_name => 'UserSegmentCache'
  serialize :segment_options
  serialize :fields

  belongs_to :market_segment, :dependent => :destroy

  validates_presence_of :name
  validates_presence_of :segment_type
  validates_presence_of :segment_options_text, :if => Proc.new { |seg| seg.segment_type == 'filtered' }
  validates_presence_of :order_by
  validates_presence_of :order_direction

  has_options :segment_type, [['Filtered', 'filtered'], ['Custom', 'custom']]
  has_options :order_direction, [['Ascending', 'ASC'], ['Descending', 'DESC']]

  has_options :status,
    [['New', 'new'],
     ['Finished', 'finished'],
     ['Refreshing', 'refreshing'],
     ['Calculating', 'calculating'],
     ['Adding', 'adding'],
     ['Removing', 'removing'],
     ['Sorting', 'sorting']]
    
  def ready?; self.status == 'finished'; end

  def fields
    self.read_attribute(:fields) || []
  end

  def before_validation #:nodoc:
    self.order_by = 'created_at' if self.order_by.blank?
    self.order_direction = 'DESC' if self.order_direction.blank?
  end

  def validate
    self.errors.add(:segment_options_text, nil, :message => self.operations.failure_reason) if self.segment_options_text && self.segment_options.nil?
  end

  def operations
    return @filter if @filter
    @filter = UserSegment::Filter.new
    @filter.operations = self.segment_options if self.segment_options
    @filter
  end

  def segment_options_text=(text)
    text = text.gsub("\r", '').strip
    self.should_refresh = self.segment_options_text != text
    self.write_attribute :segment_options_text, text
    @filter = UserSegment::Filter.new
    @filter.parse text
    if @filter.valid?
      self.segment_options = self.operations.to_a
    else
      self.segment_options = nil
    end
    text
  end

  def order_by=(order)
    self.should_refresh = self.order_by != order
    self.write_attribute :order_by, order
    order
  end

  def order_direction=(direction)
    self.should_refresh = self.order_direction != direction
    self.write_attribute :order_direction, direction
    direction
  end

  def should_refresh
    @should_refresh
  end

  def should_refresh=(refresh)
    @should_refresh ||= refresh
  end

  def should_refresh?
    self.should_refresh
  end

  def refresh
    if self.status == 'new' || self.ready?
      self.status = 'refreshing'
      self.save

      if self.segment_type == 'filtered'
        if EndUser.count < 50000
          self.cache_ids
        else
          self.run_worker(:cache_ids)
        end
      elsif self.segment_type == 'custom'
        self.add_ids []
      end
    end
  end

  def cache_ids(opts={})
    self.status = 'calculating'
    self.save

    self.sort_ids self.operations.end_user_ids
  end

  def add_ids(ids)
    self.status = 'adding'
    self.save

    ids = (self.end_user_ids + ids).uniq
    self.sort_ids ids
  end

  def remove_ids(ids)
    self.status = 'removing'
    self.save

    ids = (self.end_user_ids - ids).uniq

    self.sort_ids ids
  end

  def sort_ids(ids)
    self.status = 'sorting'
    self.save

    self.user_segment_caches.delete_all

    sort_field = UserSegment::FieldHandler.sortable_fields[self.order_by.to_sym]
    scope = EndUser.scoped(sort_field[:handler].order_options(self.order_by, self.order_direction))
    ids = scope.find(:all, :select => 'DISTINCT end_users.id', :conditions => {:id => ids, :client_user_id => nil}).collect &:id

    num_segements = (ids.length / UserSegmentCache::SIZE)
    num_segements = num_segements + 1 if (ids.length % UserSegmentCache::SIZE) > 0

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
    self.user_segment_caches.inject([]) do |ids, segement|
      ids + segement.id_list
    end
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
    nil
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
    items = cache ? cache.fetch_users(:offset => (offset % UserSegmentCache::SIZE), :limit => page_size, :include => args[:include]) : []

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

  def self.fields_options(opts={})
    UserSegment::FieldHandler.display_fields(opts).collect { |field, info| [info[:handler].field_heading(field), field.to_s] }.sort { |a, b| a[0] <=> b[0] }
  end

  def self.order_by_options(opts={})
    UserSegment::FieldHandler.sortable_fields(opts).collect { |field, info| [info[:handler].field_heading(field), field.to_s] }.sort { |a, b| a[0] <=> b[0] }
  end

  def to_expr
    self.operations.to_expr
  end

  def to_builder
    self.operations.to_builder
  end

  def after_create #:nodoc:all
    self.market_segment = MarketSegment.create(:name => self.name ,:segment_type => 'user_segment',
                                               :options => {:user_segment_id =>  self.id},
                                               :description => 'Sends a Campaign to all users in this list'.t)
    self.save
  end

  def after_save #:nodoc:all
    if self.market_segment && self.market_segment.name != self.name
      self.market_segment.name = self.name
      self.market_segment.save
    end
  end

  def self.create_copy(id)
    segment_to_copy = UserSegment.find_by_id(id)
    return nil unless segment_to_copy

    @segment = UserSegment.new segment_to_copy.attributes.symbolize_keys.slice(:name, :description, :fields, :main_page, :segment_options_text, :order_by, :segment_type)
    @segment.name += ' (Copy)'

    return nil unless @segment.save
    @segment.refresh
    @segment
  end

  def list_name
    if self.segment_type == 'filtered'
      self.name + ' (Filtered)'
    else
      self.name + ' (Custom)'
    end
  end

  def self.segment_fields(fields)
    fields.collect { |field| UserSegment::Field.new :field => field }
  end

  def self.get_handlers_data(ids, segment_fields)
    handlers = {}
    segment_fields.each { |sf| handlers[sf.handler_class] ||= []; handlers[sf.handler_class] << sf.model_field }

    data = {}
    handlers.each { |handler, fields| data[handler.to_s] = handler.get_handler_data(ids, fields) }
    data
  end
end

