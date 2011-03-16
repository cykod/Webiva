# Copyright (C) 2009 Pascal Rettig.


=begin rdoc
SiteVersion's in principle allow a single database to have multiple site trees.

This functionality isn't exposed via an interface however so for now your website's will just
have to be happy with one. 

=end
class SiteVersion < DomainModel


  validates_presence_of :name

  attr_accessor :copy_site_version_id
  
  has_many :site_nodes,:order => 'lft', :dependent => :destroy

  # Returns the default site Version (or creates one automatically)
  def self.default
    self.find(:first,:order => 'id') || self.create(:name => 'Main Tree'.t)
  end

  def self.current(force=false)
    version = DataCache.local_cache('site_version_current')
    return version if version && !force

    version = self.find_by_id(DomainModel.site_version_id) || self.default 
    DataCache.put_local_cache('site_version_current',version)
  end

  def self.override_current(version)
     DataCache.put_local_cache('site_version_current',version)
  end

  def can_delete?
    ! Domain.current_site_domains.detect { |dmn| dmn.site_version_id == self.id }
  end

  # Returns the root node of this site version or creates one (and a associated home page)
  def root_node
    @root_node ||= self.site_nodes.find(:first,:conditions => 'parent_id IS NULL')

    unless @root_node
      @root_node = site_nodes.create(:node_type => 'R', :title => '')
      home_page = site_nodes.create(:node_type => 'P')
      home_page.active_revisions[0].update_attribute(:menu_title,'Home') if home_page.active_revisions[0]
      home_page.move_to_child_of(@root_node)
    end

    
    @root_node
  end

  alias_method :root, :root_node

   # get a nested structure with 1 DB call
  def nested_pages(closed = [])
    page_hash = {self.root_node.id => self.root_node }

    nds = self.site_nodes.find(:all,
                               :conditions => [ 'lft > ?',self.root_node.lft],
                               :order => 'lft',
                               :include => :site_node_modifiers)
    nds.each do |nd|
      nd.closed = true if closed.include?(nd.id) || nd.node_options.closed
      page_hash[nd.parent_id].child_cache << nd  if page_hash[nd.parent_id]
      page_hash[nd.id] = nd
    end

    @root_node
  end

  # Given a list of nested_pages, returns any archived nodes and their children
  def self.remove_archived(nd)
    new_child_cache = nd.child_cache.map do |node|
      node.archived? ? nil : SiteVersion.remove_archived(node)
    end.compact
    nd.child_cache_set(new_child_cache)
    nd
  end

  def copy_site_version
    @copy_site_version ||= SiteVersion.find_by_id(@copy_site_version_id) if @copy_site_version_id
  end

  def copy(new_name)
    new_version = SiteVersion.create :name => new_name, :default_version => false
    return new_version unless new_version.id
    new_root = new_version.site_nodes.new :node_type => 'R', :title => ''
    new_root.copying = true
    new_root.save
    new_root.copy_modifiers self.root
    self.root.children.each { |child| new_root.copy(child, :children => true) }
    new_root.fix_paragraph_options self, :children => true
    new_version
  end
end
