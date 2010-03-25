# Copyright (C) 2009 Pascal Rettig.


=begin rdoc
SiteVersion's in principle allow a single database to have multiple site trees.

This functionality isn't exposed via an interface however so for now your website's will just
have to be happy with one. 

=end
class SiteVersion < DomainModel


  has_many :site_nodes,:order => 'lft'

  # Returns the default site Version (or creates one automatically)
  def self.default
    self.find(:first,:order => 'id') || self.create(:name => 'Default')
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
      nd.closed = true if closed.include?(nd.id)
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
  
end
