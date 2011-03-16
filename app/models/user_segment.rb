
=begin rdoc
A user segment is a stored list of user ids. There are 2 types of user segments.
A custom segment is a list of selected users.  A filtered segment contains a 
filter which is stored in the segment options. This filter is used to generate a
list of user ids to store.

Ex: Setting the filter to registered.is(true) would store all the registered users
in a user segment.

=end
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

  # Determines if the segment is ready for use.
  def ready?; self.status == 'finished'; end

  # A list of fields to display
  def fields
    self.read_attribute(:fields) || []
  end

  def before_validation #:nodoc:
    self.order_by = 'created' if self.order_by.blank?
    self.order_direction = 'DESC' if self.order_direction.blank?
  end

  def validate #:nodoc:
    self.errors.add(:segment_options_text, nil, :message => self.operations.failure_reason) if self.segment_options_text && self.segment_options.nil?
    self.errors.add(:order_by, 'is invalid') unless self.class.order_by_options.rassoc(self.order_by)
    self.errors.add(:order_direction, 'is invalid') unless self.class.order_direction_options_hash[self.order_direction]
  end

  # Returns the filter used to generate the segment.
  def operations
    return @filter if @filter
    @filter = UserSegment::Filter.new
    @filter.operations = self.segment_options if self.segment_options
    @filter
  end

  def segment_options_text=(text) #:nodoc:
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

  def order_by=(order) #:nodoc:
    self.should_refresh = self.order_by != order
    self.write_attribute :order_by, order
    order
  end

  def order_direction=(direction) #:nodoc:
    self.should_refresh = self.order_direction != direction
    self.write_attribute :order_direction, direction
    direction
  end

  def order
    if self.order_direction == 'ASC'
      self.order_by
    else
      "#{self.order_by} DESC"
    end
  end

  def should_refresh #:nodoc:
    @should_refresh
  end

  def should_refresh=(refresh) #:nodoc:
    @should_refresh ||= refresh
  end

  # Determines whether or not to refresh the segment based on changes to the model.
  def should_refresh?
    self.should_refresh
  end

  # Refreshes the segment.
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

  def resort(order)
    field, direction = order.to_s.split(' ')
    direction = 'ASC' if direction.blank?
    self.order_by = field
    self.order_direction = direction
    if self.save
      if self.should_refresh?
        if self.last_count < 50000
          self.sort
        else
          self.run_worker(:sort)
        end
      end
    end
  end

  # Sorts the ids
  def sort(opts={})
    self.sort_ids(self.end_user_ids, :sort_only => true)
  end

  # Use the filter to store a list of user ids.
  def cache_ids(opts={})
    self.status = 'calculating'
    self.save

    self.sort_ids self.operations.end_user_ids
  end

  # Adds the user ids to the segment.
  def add_ids(ids)
    self.status = 'adding'
    self.save

    ids = (self.end_user_ids + ids).uniq
    self.sort_ids ids
  end

  # Removes the user ids from the segment.
  def remove_ids(ids)
    self.status = 'removing'
    self.save

    ids = (self.end_user_ids - ids).uniq

    self.sort_ids ids
  end

  # Sort the user ids based on the order_by and order_direction.
  def sort_ids(ids, opts={})
    self.status = 'sorting'
    self.save

    self.user_segment_caches.delete_all

    # remove client users
    ids = EndUser.find(:all, :select => 'id', :conditions => {:id => ids, :client_user_id => nil}).collect &:id

    self.order_by ||= 'created'
    self.order_direction ||= 'DESC'

    sort_field = UserSegment::FieldHandler.sortable_fields[self.order_by.to_sym]
    scope = sort_field[:handler].sort_scope(self.order_by, self.order_direction)
    end_user_field = sort_field[:handler].user_segment_fields_handler_info[:end_user_field] || :end_user_id
    scope = scope.scoped(:select => "DISTINCT #{end_user_field}") unless scope.proxy_options[:select]
    sorted_ids = scope.find(:all, :conditions => {end_user_field => ids}).collect &end_user_field

    ids = sorted_ids + (ids - sorted_ids)

    num_segements = (ids.length / UserSegmentCache::SIZE)
    num_segements = num_segements + 1 if (ids.length % UserSegmentCache::SIZE) > 0

    (0..num_segements-1).each do |idx|
      start = idx * UserSegmentCache::SIZE
      self.user_segment_caches.create :id_list => ids[start..start+UserSegmentCache::SIZE-1], :position => idx
    end

    self.status = 'finished'
    self.last_ran_at = Time.now unless opts[:sort_only]
    self.last_count = ids.length unless opts[:sort_only]
    self.save
  end

  # Returns all the user ids.
  def end_user_ids
    self.user_segment_caches.inject([]) do |ids, segement|
      ids + segement.id_list
    end
  end

  # Loops through each user in the segment.
  #
  # yields user
  def each(opts={}, &block)
    self.user_segment_caches.each do |segement|
      segement.each opts, &block
    end
  end

  # Loops through each user collecting data specified by the block.
  #
  # yields user
  def collect(opts={}, &block)
    data = []
    self.user_segment_caches.each do |segement|
      data = data + segement.collect(opts, &block)
    end
    data
  end

  # Loops through each user in the segment.
  #
  # yields user, idx
  def each_with_index(opts={}, &block)
    idx = 0
    self.user_segment_caches.each do |segement|
      idx = segement.each_with_index idx, opts, &block
    end
  end

  # Finds a specific user in the segment.
  def find(opts={}, &block)
    self.user_segment_caches.each do |segement|
      user = segement.find opts, &block
      return user if user
    end
    nil
  end

  # Loops through batches of users. Useful when pulling additional user data from other models.
  #
  # yields users
  def find_in_batches(opts={}, &block)
    self.user_segment_caches.each do |segement|
      segement.find_in_batches(opts, &block)
    end
  end

  def batch_users(opts={})
    offset = opts.delete(:offset).to_i
    limit = opts.delete(:limit)

    cache_offset = offset % UserSegmentCache::SIZE

    ids = []
    ((offset / UserSegmentCache::SIZE).to_i..self.user_segment_caches.length-1).each do |position|
      cache = self.user_segment_caches.find_by_position(position)
      ids += cache.id_list[cache_offset...(cache_offset+limit-ids.length)]
      cache_offset = 0
      break if ids.length >= limit
    end

    EndUser.find :all, :conditions => {:id => ids}
  end

  # Used to paginate a list of users, returns the same pagination hash as DomainModel.paginate
  # and a list of users
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

  # Returns the offset of the last user found and the list of users
  #
  # Search criteria can be specified in 2 ways.
  #
  # Using a condition
  # args = {:conditions => ["created_at > ? ", 7.days.ago]}
  #
  # Using a scope
  # args = {:scope => EndUserCache.search('pascal'), :end_user_field => :end_user_id}
  #
  # Specifying a scope can be useful. It allows you to search for users in another model from a segment.
  #
  # args[:offset] is the index of first user to search
  #
  # args[:limit] is the maximum number of users to return
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

  def before_create #:nodoc:
    self.status = 'new'
  end

  # Returns a list of display fields
  def self.fields_options(opts={})
    UserSegment::FieldHandler.display_fields(opts).collect { |field, info| [info[:handler].field_heading(field), field.to_s] }.sort { |a, b| a[0] <=> b[0] }
  end

  def self.fields_group_options(opts={})
    group_options = []
    seen_options = {}
    display_fields = UserSegment::FieldHandler.display_fields(opts)
    UserSegment::FieldHandler.handlers.each do |handler|
      options = []
      handler[:class].user_segment_fields.each do |field, values|
        next unless display_fields[field]
        next if seen_options[field.to_s]
        options << ['-  ' + values[:name], field.to_s]

        if values[:display_methods]
          values[:display_methods].each do |name, method|
            field_method = "#{field}_#{method}"
            options << ['-  ' + name, field_method]
          end
        end

        seen_options[field.to_s] = 1
      end

      unless options.empty?
        options.sort! { |a, b| a[0] <=> b[0] }
        group_options << [handler[:name], options]
      end
    end
    group_options
  end

  # Returns a list of sortable fields
  def self.order_by_options(opts={})
    UserSegment::FieldHandler.sortable_fields(opts).collect { |field, info| [info[:handler].field_heading(field), field.to_s] }.sort { |a, b| a[0] <=> b[0] }
  end

  def self.order_by_group_options(opts={})
    group_options = []
    seen_options = {}
    sortable_fields = UserSegment::FieldHandler.sortable_fields(opts)
    UserSegment::FieldHandler.handlers.each do |handler|
      options = []
      handler[:class].user_segment_fields.each do |field, values|
        next unless sortable_fields[field]
        next if seen_options[field.to_s]
        options << ['-  ' + values[:name], field.to_s]
        seen_options[field.to_s] = 1

        if values[:sort_methods]
          values[:sort_methods].each do |name, method|
            field_method = "#{field}_#{method}"
            options << ['-  ' + name, field_method]
          end
        end
      end

      unless options.empty?
        options.sort! { |a, b| a[0] <=> b[0] }
        group_options << [handler[:name], options]
      end
    end
    group_options
  end

  # Returns the text version of the filter
  def to_expr
    self.operations.to_expr
  end

  # Returns the hash used to setup the UserSegment::OperaionBuilder
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

  # Creates a copy of the segment.
  def self.create_copy(id)
    segment_to_copy = UserSegment.find_by_id(id)
    return nil unless segment_to_copy

    @segment = UserSegment.new segment_to_copy.attributes.symbolize_keys.slice(:name, :description, :fields, :main_page, :segment_options_text, :order_by, :segment_type)
    @segment.name += ' (Copy)'

    return nil unless @segment.save
    @segment.refresh
    @segment
  end

  # Returns the name of the segment with its type.
  def list_name
    if self.segment_type == 'filtered'
      self.name + ' (Filtered)'
    else
      self.name + ' (Custom)'
    end
  end

  # Returns the data required to output the fields value.
  def self.get_handlers_data(ids, fields)
    handlers = {}
    fields.each do |field|
      info = UserSegment::FieldHandler.display_fields[field.to_sym]
      next unless info
      handlers[info[:handler]] ||= []
      handlers[info[:handler]] << field.to_sym
    end

    data = {}
    handlers.each { |handler, fields| data[handler.to_s] = handler.get_handler_data(ids, fields) }
    data
  end
end

