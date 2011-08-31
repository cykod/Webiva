# Copyright (C) 2009 Pascal Rettig.



class SiteNode < DomainModel

  SiteNodePageInformation = Struct.new(:site_template,:revision,:frameworks,:paragraphs,:head,:title)
  
  SiteNodeRedirectInformation = Struct.new(:redirect_to,:message)

  validates_presence_of :node_type

  has_many :pages, :class_name => "SiteNode", :foreign_key => :parent_id, 
            :conditions => 'node_type = "P"'
            
  has_many :page_revisions, :dependent => :destroy, :order => "revision DESC, language", 
  				:as => :revision_container
  has_many :live_revisions, :class_name => 'PageRevision', :as => :revision_container, :conditions => 'active=1 AND revision_type="real"'
          
  belongs_to :site_module,
              :foreign_key => 'node_data'

  belongs_to :experiment, :dependent => :destroy

  belongs_to :domain_file,
              :foreign_key => 'node_data'

  belongs_to :site_version
  validates_presence_of :site_version
              
  has_many :site_node_modifiers, :order => 'site_node_modifiers.position', :dependent => :destroy
  
  has_one :redirect_detail, :dependent => :destroy
  
  has_one :page_modifier, :class_name => 'SiteNodeModifier', :conditions => 'modifier_type IN ("P","page")'

  content_node :except => Proc.new { |sn| sn.node_type != 'P' }, :content_url_override => :node_path

  acts_as_nested_set :scope => :site_version_id 
  
  attr_accessor :page_info, :closed

  named_scope :with_type, lambda { |type| {:conditions => {:node_type => type}} }

  attr_accessor :created_by_id, :copying

  # Expires the entire site when save or deleted
  expires_site

  def is_running_an_experiment?
    self.experiment_id && self.experiment && self.experiment.is_running? && self.experiment.active?
  end

  def experiment_version(session)
    return nil unless self.experiment
    self.experiment.get_version(session)
  end

  def experiment_page_revision(session)
    return @experiment_page_revision if @experiment_page_revision
    version = self.experiment_version(session)
    return nil unless version
    @experiment_page_revision = self.page_revisions.first :conditions => {:revision => version.revision, :language => version.language, :revision_type => 'real'}
  end

  def before_validation #:nodoc:
    self.node_type = 'P' if self.node_type.blank?
  end

  def child_cache #:nodoc:
    @child_cache ||= []
  end

  def child_cache=(val) #:nodoc:
    @child_cache ||= []
    @child_cache << val
  end

  def child_cache_set(val) #:nodoc:
    @child_cache = val
  end

  # Returns an array of elements for how this 
  # site node should be represented in a menu
  def menu
    if self.node_type == 'P'
      [ self ]
    elsif self.node_type == 'M'
      self.dispatcher.menu
    elsif self.node_type == 'G'
      @child_cache || self.children
    else
      [ self ]
    end
  end

  # returns a nested set of pages starting with the current element
  def nested_pages(closed = [])
    page_hash = {self.id => self}

    nds = SiteNode.find(:all,
                               :conditions => [ 'lft > ? AND rgt < ? AND site_version_id=?',self.lft,self.rgt,self.site_version_id],
                               :order => 'lft',
                               :include => :live_revisions)
    nds.each do |nd|
      nd.closed = true if closed.include?(nd.id)
      page_hash[nd.parent_id].child_cache << nd  if page_hash[nd.parent_id]
      page_hash[nd.id] = nd
    end

    self
  end



  # Find a page by id (only returns pages)
  def self.find_page(page_id)
    self.with_type('P').find_by_id(page_id)
  end 
  
  
  # Returns the path of a site node based on id, optionally using the default url if the page doesn't exist
  def self.get_node_path(page_id,default_url = nil)
    nd = self.find_by_id(page_id)
    return nd.node_path if nd
    default_url
  end
  
  # Alias of get_node_path
  def self.node_path(page_id,default_url=nil)
    self.get_node_path(page_id,default_url)
  end


  # Adds a modifier to this nodes list of modifiers
  def add_modifier(type,options={})
    returning md = self.site_node_modifiers.create(options.merge(:modifier_type => type)) do
      md.move_to_top
      if block_given?
        yield md
        md.save
      end
    end
  end

  # Adds a subpage with the suburl of title to this page
  def add_subpage(title,type = 'P')
    nd = SiteNode.create(:title => title,:site_version_id => self.site_version_id,:node_type => type)
    nd.move_to_child_of(self) if nd.id
    nd
  end
  
  def self.generate_node_path(title)
    title.underscore.gsub(/[^a-z0-9 _\-]/, '').strip.gsub(/[ _]+/, '-')
  end

  def new_revision
    rv = self.live_revisions.first.create_temporary
    yield rv
    rv.make_real
    rv
  end

  def push_subpage(title, type='P')
    nd = self.site_version.site_nodes.with_type(type).find_by_title(title) || self.add_subpage(title, type)
    if block_given?
      # only pages have revisions
      if type == 'P'
        rv = nd.live_revisions.first.create_temporary
        yield nd, rv
        rv.make_real
      else
        yield nd
      end
    end
    nd
  end

  def push_modifier(type)
    md = self.site_node_modifiers.find_by_modifier_type(type) || self.add_modifier(type)
    if block_given?
      yield md
    end
    md
  end

  def create_temporary_revision(revision_id) #:nodoc:
    rev = self.page_revisions.find_by_id(revision_id)
    return nil unless rev
    rev.create_temporary
  end

  # Returns the name of this page, either pulling from the revision
  # title or titleizing the url
  def name
    lang = Configuration.languages[0]

    rev = self.live_revisions.find_by_language(lang)
    if rev && !rev.title.blank?
      str = rev.variable_replace(rev.title)
    else
      str = self.title.to_s.titleize
    end
  end

  def content_description(language) #:nodoc:
    "Site Page - %s" / self.node_path
  end
 
  def content_search_results? #:nodoc:
    self.include_in_sitemap?    
  end
  
  # Returns the active PageRevision of the passed language, or returns a revision of a different language if the passed language doesn't exist
  def active_revision(language)
    self.live_revisions.detect { |rev| rev.language == language } || self.live_revisions[0]
  end
  
  # alias for active_revision  
  def visible_revision(language)
    self.page_revisions.find(:first,:conditions => 'active=1 AND revision_type="real"', :order => "language='#{language}' DESC,revision DESC")
  end
  
  # Returns a list of revision of the passed languages, 
  # with each entry in the form:
  #   [ language, active revision or nil, latest revision or nil ]
  def language_revisions(languages)
    languages.collect do |lang|
      [ lang,
        self.page_revisions.find(:first,:conditions => ['language=? AND revision_type="real"',lang], :order => 'active DESC, revision DESC'),
        self.page_revisions.find(:first,:conditions => ['language=? AND revision_type="real"',lang], :order => 'revision DESC')
      ]
    end
  end
  
  # Returns a list of active revisions in all available languages
  def active_revisions
    self.page_revisions.find(:all,:conditions => ['active=?',true], :order => 'language')
  end
  
#  def domain_module_info #:nodoc:
#    if(self.node_type == 'M')
#      return DomainModule.get_module_info(self.module_name,self.domain)
#    else
#      raise 'Not a Domain Module'
#    end
#  end
  
  # Returns the path for this node (or returns "Domain" if this is the root node)
  def node_path
    if self.node_type == 'R'
      "Domain"
    else
      super
    end
  end
  
  def page_type #:nodoc:
    "page"
  end

  def full_framework_paragraphs(language,before_only=false,before_idx=nil)
    node_list = self.self_and_ancestors.reverse
    page_paragraphs = { }
    zone_clears =  {}

    node_list.each do |nd|
      if nd == self
        modifiers = nd.framework_and_template_modifiers(before_only,before_idx).reverse
      else 
        modifiers = nd.framework_and_template_modifiers.reverse
      end

      modifiers.each do |md|
        if md.modifier_type == 'template'
          if md.modifier_data[:clear_frameworks] == 'yes'
            break # early out
          end
        elsif md.modifier_type == 'framework'
          paras = md.active_language_revision(language).page_paragraphs
          paras.each do |para|
            if para.display_type == 'clear'
              zone_clears[para.zone_idx] = para.page_revision_id
            elsif !zone_clears[para.zone_idx] || zone_clears[para.zone_idx] == para.page_revision_id
              page_paragraphs[para.zone_idx] ||= []
              page_paragraphs[para.zone_idx] << para
            end
          end
        end
      end
    end
    page_paragraphs.values.inject([]) { |a,b| a + b }
  end


  def framework_and_template_modifiers(before_only=false,before_idx=nil)
    self.modifiers(before_only,before_idx).select { |md| md.modifier_type == 'framework' || md.modifier_type == 'template' }
  end


  
  # Returns a list of modifiers, optionally only those before
  # the page (and then optionally only those before the passed index)
  def modifiers(before_only=false,before_idx=nil)
    if before_only
      self.site_node_modifiers.find(
                                    :all, 
                                    :conditions =>
                                    ["modifier_type NOT IN ('P','page') AND position < ?",
                                     before_idx ? before_idx : page_modifier.position
                                    ],
                                    :order => 'position')
    else
      self.site_node_modifiers.find(:all,
                                    :conditions => "modifier_type NOT IN ('P','page')",
                                    :order => :position)
    end
  end
  
  # Returns a select-friendly list of pages with urls (group nodes not included)
  # optionally including the root node as well
  #
  #  Options
  #     version - a passed in site version to use, otherwise defaults to SiteVersion.current
  def self.page_options(include_root = false, opts={})
    node_type = include_root ? 'node_type IN("P","R","M","J")' : 'node_type IN ("P","M","J")'
    site_version = opts[:version] || SiteVersion.current 
    SiteNode.find(:all,:conditions => [node_type + " AND site_version_id=? ",site_version.id],
                  :order => 'lft').collect do |page|
      [ page.node_type != 'R' ? page.node_path : include_root , opts[:url] ? page.node_path : page.id ]
    end
  end

  # Returns a select-friendly list of pages with urls (group nodes not included)
  # optionally including the root node as well
  def self.page_url_options(include_root = false)
    self.page_options(include_root, :url => true)
  end

  # Returns a select-friendly list of pages and groups
  #  optionally including the root node as well
  def self.page_and_group_options(include_root = false)
    node_type = include_root ? 'node_type IN("P","R","M","J","G")' : 'node_type IN ("P","M","J","G"")'
    SiteNode.find(:all,:conditions => node_type,
                  :order => 'lft').collect do |page|
      title = case page.node_type
              when 'R': include_root
              when 'P': page.node_path
              when 'G': "#{page.node_path} (#{page.title})"
              end
      [ title, page.id ]
    end
  end
  
  # Returns a select-friendly list of modules that match that have a module_name of  mod
  def self.module_options(mod)
    SiteNode.find(:all,:conditions => [ 'module_name = ? AND node_type = "M" ',mod],
                  :order => 'node_path').collect do |page|
      [ page.node_path + " (Module)".t ,page.id ]
    end
  end
  
  
  # Return the constantized class of the dispatcher for this SiteNode, useful only for
  # M(odule) type nodes
  def dispatcher_class    
    "#{module_namespace.camelcase}::#{options_action.camelcase}Dispatcher".constantize
  end
  
  # Return a new instance of the dispatcher class  (M nodes only)
  def dispatcher
    dispatcher_class.new(self)
  end
  
  # Return the module namespace of this SiteNode (M nodes only)
  def module_namespace
    self.module_name[1..-1].split("/")[0]
  end
  
  # Returns the options controller name for this site node  (M nodes only)
  def options_controller
    "/" + self.module_name[1..-1].split("/")[0] + "/admin"
  end
  
  def options_action #:nodoc:
    self.module_name[1..-1].split("/")[1]
  end

  # Deprecated
  def self.update_paragraph_links(old_path,new_path) #:nodoc:
    return if(old_path == new_path)
    

    reg = Regexp.new("<a([^>]*?)href=(\\\"|\')(#{Regexp.quote(old_path)})([^>]*)\>",Regexp::IGNORECASE| Regexp::MULTILINE)

     PageParagraph.find(:all,:conditions => "display_type = 'html' AND display_body LIKE " + DomainModel.connection.quote("%" + old_path + "%")).each do |para|
      
      fixed_body = ''
      text_body = para.display_body
      while( mtch = reg.match(text_body) ) 

        fixed_body += mtch.pre_match
        fixed_body += "<a #{mtch[1]} href=#{mtch[2]}#{new_path}#{mtch[4]}>"
        text_body = mtch.post_match
      end
      para.update_attribute(:display_body,fixed_body + text_body)

    end


  end
  
  # Make a deep copy of this site node including all live revisions
  def duplicate!(parent)
    atr = self.attributes
    atr.delete(lft)
    atr.delete(rgt)
    nd = SiteNode.new(atr)
    nd.title += '_copy'

    nd.save
    
    self.live_revisions.each do |rev|
      tmp_rev = rev.create_temporary
      tmp_rev.revision_container = nd
      tmp_rev.save
      tmp_rev.make_real
    end

    nd.move_to_child_of(parent)
    
    nd
  end


  def node_options(val=nil)
    case self.node_type
    when 'G': GroupNodeOptions.new(val || self.page_modifier.modifier_data ||{})
    else NodeOptions.new(val || self.page_modifier.modifier_data || {})
    end
  end

  def set_node_options(val)
    opts = self.node_options(val)
    self.page_modifier.update_attributes(:modifier_data => opts.to_hash)
    opts
  end

  class NodeOptions < HashModel

  end


  class GroupNodeOptions < NodeOptions
    attributes :closed => false

    boolean_options :closed
  end


  def page_content(limit = 5)
    return @page_content if @page_content

    content_type_ids = ContentType.find(:all,:select => 'id', :conditions => { :detail_site_node_url => self.node_path }).map(&:id)

    begin
      @page_content = ContentNode.find(:all,:conditions => { :content_type_id => content_type_ids },:include => :node, :order => 'created_at DESC', :limit => limit )
    rescue Exception => e
      @page_content = ContentNode.find(:all,:conditions => { :content_type_id => content_type_ids }, :order => 'created_at DESC', :limit => limit )

    end

    @page_content
  end
  
  def can_index?
    return false if self.index_page == 0

    self.self_and_ancestors.reverse.each do |nd|
      return false if nd.index_page == 0
    end

    true
  end

  protected
  
  def after_create #:nodoc:
    return if @copying

    if self.node_type == 'P'
      self.page_revisions.create( :language => Configuration.languages[0], :revision => '0.01', :active => 1, :created_by_id => self.created_by_id )
      self.page_revisions[0].page_paragraphs.create(:display_type => 'html', :zone_idx => 1 )
    elsif self.node_type == 'J'
      redirect_detail = self.create_redirect_detail(:redirect_type => 'site_node')
    elsif self.node_type == 'M'
      self.page_revisions.create( :language => Configuration.languages[0], :revision => '0.01', :active => 1 )
    end
    
    self.site_node_modifiers.create(:modifier_type => 'page')
  end
  
  def before_save #:nodoc:
    node_path = ''
    if self.parent && self.parent.node_path && (self.parent.node_type == 'P' || self.parent.node_type == 'G')
      node_path = self.parent.node_path
    end
    
    unless node_path[-1..-1] == '/'
      node_path += '/'
    end
    
    if self.node_type != 'G'
      node_path +=  self.title.to_s
    end
    
    self.node_path = node_path
    self.node_level = self.parent ?  self.parent.node_level.to_i + 1 : 0
    
  end
  
  def after_save #:nodoc:
    unless self.frozen?
      if self.children.length > 0
        self.children.each do |child|
          child.save unless child.frozen?
        end
      end
    end
  end

  def content_node_body(language)  #:nodoc:
    rev = self.live_revisions.detect { |rev| rev.language == language }
    if rev
      paragraphs = rev.page_paragraphs.find(:all,:conditions => "display_module IS NULL")
      paragraphs.map { |para| para.display }.join(" ")
    else
      nil
    end
  end

  def self.content_admin_url(node_id) #:nodoc:
     {:controller => '/edit', :action => 'page',
      :path => [ 'page', node_id ] }
  end

  public

  def admin_url
    self.class.content_admin_url self.id
  end

  def self.chart_traffic_handler_info
    {
      :name => 'Page Traffic',
      :title => :node_path,
      :icon => 'traffic_page.png',
      :url => { :controller => '/emarketing', :action => 'charts', :path => ['traffic'] + self.name.underscore.split('/') }
    }
  end

  def self.traffic_scope(from, duration, opts={})
    scope = DomainLogEntry.valid_sessions.between(from, from+duration).hits_n_visits('site_node_id')
    scope = scope.scoped(:conditions => {:site_node_id => opts[:target_id]}) if opts[:target_id]
    scope
  end

  def self.traffic(from, duration, intervals, opts={})
    DomainLogGroup.stats(self.name, from, duration, intervals, :type => 'traffic', :target_id => opts[:target_id]) do |from, duration|
      self.traffic_scope from, duration, opts
    end
  end

  def traffic(from, duration, intervals)
    self.class.traffic from, duration, intervals, :target_id => self.id
  end

  def link(*paths)
    SiteNode.link self.node_path, *paths
  end

  def self.link(*paths)
    '/' + paths.map{ |p| p && p[0..0] == '/' ? p[1..-1] : p }.reject(&:blank?).join('/')
  end

  def domain_link(*paths)
    SiteNode.domain_link self.node_path, *paths
  end

  def self.domain_link(*paths)
    Configuration.domain_link(SiteNode.link(*paths))
  end
  
  def copy_modifiers(node)
    node.site_node_modifiers.each do |mod|
      attrs = mod.attributes
      %w(id site_node_id position).each { |fld| attrs.delete(fld) }
      new_mod = self.site_node_modifiers.new attrs
      new_mod.copying = true
      new_mod.save
      new_mod.copy_live_revisions mod
    end
  end
  
  def copy(node, opts={})
    attrs = node.attributes
    nd = SiteNode.new attrs
    nd.site_version_id = self.site_version_id
    nd.copying = true
    nd.save
    
    nd.copy_modifiers node

    node.live_revisions.each do |rev|
      tmp_rev = rev.create_temporary
      tmp_rev.revision_container = nd
      tmp_rev.save
      tmp_rev.make_real
    end

    nd.move_to_child_of(self)
    
    nd.save
    
    node.children.each { |child| nd.copy(child, opts) } if opts[:children]
    
    nd
  end
  
  def fix_paragraph_options(from_version, opts={})
    self.live_revisions.each { |rev| rev.fix_paragraph_options(from_version, self.site_version, opts) }
    self.site_node_modifiers.each { |mod| mod.fix_paragraph_options(from_version, self.site_version, opts) }
    self.children.each { |child| child.fix_paragraph_options(from_version, opts) } if opts[:children]
  end
end
