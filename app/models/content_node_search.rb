
class ContentNodeSearch < HashModel
  attr_reader :total_results

  attributes :terms => nil, :per_page => 10, :content_type_id => nil, :page => 1, :max_per_page => 50, :protected_results => false, :category_id => nil, :published_before => nil, :published_after => nil

  integer_options :per_page, :page, :content_type_id, :max_per_page
  boolean_options :protected_results
  date_options :published_after, :published_before

  def validate
    errors.add(:page) if self.page < 1
    errors.add(:per_page) if self.per_page > self.max_per_page || self.per_page < 1
    errors.add(:content_type_id) if ! self.valid_content_type?
  end

  def search?
    ! self.terms.blank?
  end

  def valid_content_type?
    ! self.content_types_options.rassoc(self.content_type_id).nil?
  end

  # if they are logged in they can see protected results
  def set_protected_results(myself)
    self.protected_results = myself.id ? true : false
  end

  def content_types_options(backend = false)
#    return @content_types_options if @content_types_options
    if backend
      opts = {}
    else
      opts = { :conditions => {:search_results => 1} }
      opts[:conditions][:protected_results] = 0 if self.protected_results.blank?
    end
    @content_types_options = ContentType.select_options_with_nil 'Everything', opts
  end

  def self.content_types_options
    opts = { :conditions => {:search_results => 1} }
    ContentType.select_options_with_nil 'Everything', opts
  end

  def language
    return @language if @language
    @language = Configuration.languages[0]
  end

  def language=(language)
    @language = language
  end

  def content_type
    @content_type ||= ContentType.find_by_id self.content_type_id
  end

  def categories
    return @categories if @categories
    @categories = []
    return @categories unless self.content_type
    return @categories unless self.content_type.container
    return @categories unless self.content_type.container.respond_to?(:content_categories)
    @categories = self.content_type.container.content_categories
  end

  def category_options
    [['All'.t, nil]] + self.categories.collect { |c| [c.name, c.id] }
  end

  def category_content_node_ids
    return unless self.category_id
    self.content_type.container.content_category_nodes(self.category_id).collect(&:id)
  end

  def frontend_search(order_by = nil)
    return [@pages, @results] if @results

    conditions = {:search_result => 1}
    conditions[:content_type_id] = self.content_type_id if self.content_type_id
    conditions[:protected_result] = 0 if self.protected_results.blank?
    conditions[:content_node_id] = self.category_content_node_ids if self.category_id && self.content_type_id
    conditions['content_nodes.published_at'] = self.published_after_date..self.published_before_date if self.published_after_date && self.published_before_date

    offset = (self.page - 1) * self.per_page

    @results, @total_results = ContentNode.search(self.language, self.terms,
						  :conditions => conditions,
						  :limit => self.per_page,
						  :offset => offset,
              :order => order_by.to_s == 'date' ? 'published_at DESC' : nil
						  )
    @results = @results.map do |node|
      content_description =  node.content_description(language)
      if(!node.link.blank? && node.content_type) 
        { 
          :title => node.title,
          :subtitle => content_description || node.content_type.content_name,
          :url => node.link,
          :preview => node.preview,
          :excerpt => node.excerpt,
          :node => node
        }
      else 
        nil
      end
    end.compact

    # taken from DomainModel.paginate, makes using the pagelist_tag easier
    @pages = { :pages => (@total_results.to_f / self.per_page.to_f).ceil,
      :page => self.page, 
      :window_size => window_size, 
      :total => @total_results,
      :per_page => self.per_page,
      :first => offset+1,
      :last => offset + @results.length
      }
    [@pages, @results]
  end

  def backend_search
    return [@results, @more] if @results

    conditions = {}

    conditions[:content_type_id] = self.content_type_id if self.content_type_id

    offset = (self.page - 1) * self.per_page

    @results, @total_results = ContentNode.search(self.language, self.terms,
						  :conditions => conditions,
						  :limit => self.per_page + 1,
						  :offset => offset
						  )
    @results.map! do |node|
      content_description =  node.content_description(language)

      { 
	:title => node.title,
	:subtitle => content_description || (node.content_type && node.content_type.content_name),
	:url => node.link,
	:link => node.link,
	:preview => node.preview,
	:excerpt => node.excerpt,
	:node => node
      }
    end

    @more = @results.length > self.per_page

    [@results, @more]
  end
end
