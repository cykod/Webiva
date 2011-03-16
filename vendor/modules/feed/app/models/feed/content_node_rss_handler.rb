

class Feed::ContentNodeRssHandler

  def self.feed_rss_handler_info
    {
    :name => "Content RSS Feed"
    }
  end

  def initialize(options)
    @options = options
  end
  
  def get_feed
    data = { :title => @options.feed_title,
             :description => @options.description,
             :link => Configuration.domain_link(@options.link_url),
             :items => []}

    conditions = @options.content_type_ids.length > 0 ? {  :content_type_id => @options.content_type_ids } : nil
    @nodes = ContentNode.find(:all,:conditions => conditions, :limit => @options.limit, :order => @options.order, :include => :content_type )
    @nodes.each do |node|
      item = { :title => node.title,
               :description => '',
	       :guid => Configuration.domain_link(node.link),
               :published_at => @options.order_by == 'newest' ? node.created_at.to_s(:rfc822) : node.updated_at.to_s(:rfc822),
	       :link => Configuration.domain_link(node.link)
      }

      if node.content_type
        categories = [node.content_type.type_description, node.content_type.content_name].collect { |c| c unless c.blank? }.compact
      else
        categories = []
      end
      item[:categories] = categories unless categories.empty?
#      unless node.content_type.content_name.blank? && node.content_type.type_description.blank?
#          item[:description] = "#{node.content_type.content_name} #{node.content_type.type_description}"
#      end
      data[:items] << item
    end
      
    data
  end

  class Options < Feed::AdminController::RssModuleOptions
    attributes :content_type_ids => [], :description => nil, :link_id => nil, :limit => 10, :order_by => 'newest'
    
    integer_array_options :content_type_ids
    integer_options :limit
    page_options :link_id
    validates_numericality_of :limit
    validates_presence_of :link_id

    options_form(
           fld(:link_id,:page_selector),
           fld(:description,:text_area),
           fld(:limit,:text_field),
           fld(:order_by,:select,:options => :order_by_options,:label => "Display"),
           fld(:content_type_ids,:ordered_array,:options => :content_type_options,
               :label => "Limit by Content Type",
               :description => "Widget will show all updated content or only specific types")
                )

    def content_type_options
      ContentType.select_options
    end

    def order_by_options
      [['Newest', 'newest'], ['Recently Updated', 'updated']]
    end

    def order
      if self.order_by == 'updated'
	'updated_at DESC'
      else
	'created_at DESC'
      end
    end
  end

end
