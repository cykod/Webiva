# Copyright (C) 2009 Pascal Rettig.

=begin rdoc
This is a meta-class that represents an individual piece of content in the system

Not all DomainModel's create ContentNode's - only those that need to be system-wide
indexable. 
ContentNode's generally belong to ContentType's which allows searching by individual
types of content

### Adding content node support to a model

To add ContentNode support into a model, you should add a `content_node` call somehwere
inside your class, for example:

     content_node :container_type => 'BookBook', 
     :container_field => 'book_book_id',
     :except => Proc.new { |pg| pg.parent_id.blank? }, 
     :published => :published

and then you must add a content_description method that describes the piece of content
(in addition to it's title field), such as:

      def content_description(language)
        "Page in \"%s\" Book" / self.book_book.name
       end

See ModelExtension::ContentNodeExtension for the exact options passed to `content_node`
This allows the system to describe the piece of content to administrators.

If you want to customize what attributes show up in a search of this content node, you should
also define a method called content_node_body which takes a language as a parameter and
returns HTML or plaintext with the content that should be indexed. for example BookPage could
implement:

      def content_node_body(language)
        self.body
      end

Otherwise the system will use all string & text attributes by default

### Adding content type support to a container model

If this ContentNode has a :container_type - then the container type (in this case
BookBook) needs to call at the class level of `content_node_type` and define some additional 
methods.

For example, the BookBook class defines adds the following call to content_node_type

      content_node_type :book, "BookPage", 
          :content_name => :name,
          :title_field => :name, 
          :url_field => :url

What this means is that each BookBook that is created will add an entry to the ContentType table
and it will contain a number of BookPages. BookBook now must implement two instance methods
to provide more information about the type:


      def content_admin_url(book_page_id)
        {  :controller => '/book/manage', :action => 'edit', :path => [ self.id, book_page_id ],
           :title => 'Edit Book Page'.t}
      end

      def content_type_name
        "Book"
      end

The former returns a url_for hash for a specific piece of content while the later returns
an translatable english name for the Content Type. 

=end
class ContentNode < DomainModel

  belongs_to :node, :polymorphic => true #, :dependent => :destroy
  belongs_to :author,:class_name => 'EndUser',:foreign_key => 'author_id'
  belongs_to :last_editor,:class_name => 'EndUser',:foreign_key => 'last_editor_id'
  belongs_to :content_type
  has_many :content_node_values, :dependent => :delete_all

  named_scope :from_content do |node_type,node_id|
    { :conditions => { :node_type => node_type, :node_id => node_id } }
  end

  def self.fetch(node_type,node_id)
    self.from_content(node_type,node_id).first
  end

  def update_node_content(user,item,opts={}) #:nodoc:
    opts = opts.symbolize_keys
    if self.content_type_id.blank?
      if opts[:container_type] # If there is a container field
        container_type = item.resolve_argument(opts.delete(:container_type))
        container_field = opts.delete(:container_field)
        container_id = item.send(container_field.is_a?(Proc) ? container_field.call(item) : container_field)

        self.content_type = ContentType.find_by_container_type_and_container_id(container_type,container_id)
      else
        self.content_type = ContentType.find_by_content_type(item.class.to_s)
      end
    end

    
    opts.slice(:published,:sticky,:promoted,:content_url_override,:published_at).each do |key,opt|
      val = item.resolve_argument(opt)
      val = false if val.blank?
      self.send("#{key}=",val)
    end

    self.updated_at = Time.now
    self.published_at ||= Time.now if self.published?
    
    if opts[:user_id]
      user_id = item.resolve_argument(opts[:user_id])
    elsif item.respond_to?(:content_node_user_id)
      user_id = item.content_node_user_id(user)
    else
      user_id = user.id if user
    end
    
    if self.new_record?
      self.author_id = user_id if user_id
      self.last_editor_id = user_id if user_id
    else 
      self.last_editor_id = user_id if user_id
    end
    self.save

    if opts[:push_value]
      generate_content_values!
    end
  end


  # Returns the administration url for this content node, either
  # by querying the container or the node itself
  def admin_url
    if self.content_type
      if self.content_type.container
        if self.content_type.container.respond_to?(:content_admin_url)
          self.content_type.container.content_admin_url(self.node_id)
        else
          raise "#{self.content_type.container_type} needs to define content admin url"
        end
      else
        cls =self.content_type.content_type.constantize
        if cls.respond_to?(:content_admin_url)
          cls.content_admin_url(self.node_id)
        else
          raise "#{cls.to_s} needs to define content admin url"
        end
      end
    else
      nil
    end
  end

  # Generate a content_node_value 
  # used in search results
  def generate_content_values!(type_preload = nil,force=false)
    return unless node
    # Don't want to have to reload the type for each 
    # node we're created
    type_preload ||= self.content_type

    Configuration.languages.each do |lang|
      cnv = content_node_values.find_by_language(lang) || content_node_values.build(:language => lang,:content_type_id => self.content_type_id)

      # If we haven't updated this since we last updated the
      # content node value, just return
      if !cnv.updated_at || self.updated_at > cnv.updated_at || type_preload.updated_at > cnv.updated_at || force
        if(self.node.respond_to?(:content_node_body))
          cnv.body = Util::TextFormatter.text_plain_generator( node.content_node_body(lang))
        else
          cnv.body = Util::TextFormatter.text_plain_generator( node.attributes.values.select { |val| val.is_a?(String) }.join("\n\n") )
        end

        if type_preload
          cnv.title = node.send(type_preload.title_field)
          cnv.link = self.link
          cnv.search_result = type_preload.search_results? ? (self.node.respond_to?(:content_search_results?) ? self.node.send(:content_search_results?) : true ) : false
          cnv.protected_result = type_preload.protected_results? ?  (self.node.respond_to?(:content_protected_results?) ? self.node.send(:content_protected_results?) : true ) : false
        else
          cnv.title = "Unknown"
          cnv.link = self.content_url_override || nil
          cnv.search_result = false
          cnv.protected_result = true
        end
        cnv.save
      end
    end
  end

  def link(type_preload = nil)
    type_preload ||= self.content_type
    return "#" unless type_preload
    node ? (self.content_url_override || type_preload.content_link(node)) : ''
  end

  def title
    if self.content_type && node
      node.send(content_type.title_field)
    else
      "Unknown"
    end
  end
  
  def content_description(language) #:nodoc:
    if self.node.respond_to?(:content_description)
      self.node.content_description(language)
    else
      nil
    end
  end

  def self.batch_find(node_ids)
    self.find(:all,:conditions => { :id => node_ids },:include => :node)
  end


  # Search content in a given language given a query string
  # Will reteurn a list of ContentNodeValues using whatever search
  # handler is active
  def self.search(language,query,options = { })
    search_handler = Configuration.options.search_handler

    # Run an internal mysql fulltext search if the handler is blank
    if !search_handler.blank? &&  handler_info = get_handler_info(:webiva,:search,search_handler)
      begin
	handler_info[:class].search(language,query,options)
      rescue Exception => e
	raise e unless RAILS_ENV == 'production'
	return internal_search(language,query,options)
      end
    else
      internal_search(language,query,options)
    end
  end

  def self.internal_search(language,query,options = { }) #:nodoc:
    ContentNodeValue.search language, query, options
  end

  def self.chart_traffic_handler_info
    {
      :name => 'Content Traffic',
      :url => { :controller => '/emarketing', :action => 'charts', :path => ['traffic'] + self.name.underscore.split('/') }, :icon => 'traffic_content.png',
      :type_options => :traffic_type_options
    }
  end

  def self.traffic_type_options
    ContentType.select_options_with_nil
  end

  def self.traffic_scope(from, duration, opts={})
    scope = DomainLogEntry.valid_sessions.between(from, from+duration).hits_n_visits('content_node_id')
    if opts[:target_id]
      scope = scope.scoped(:conditions => {:content_node_id => opts[:target_id]})
    elsif opts[:type_id]
      scope = scope.scoped(:joins => :content_node, :conditions => ['`content_nodes`.content_type_id = ?', opts[:type_id]])
    else
      scope = scope.content_only
    end
    scope
  end

  def self.traffic(from, duration, intervals, opts={})
    stat_type = opts[:type_id] ? "traffic_content_type_#{opts[:type_id]}" : 'traffic'
    DomainLogGroup.stats(self.name, from, duration, intervals, :type => stat_type, :target_id => opts[:target_id]) do |from, duration|
      self.traffic_scope from, duration, opts
    end
  end

  def traffic(from, duration, intervals)
    self.class.traffic from, duration, intervals, :target_id => self.id
  end
end
