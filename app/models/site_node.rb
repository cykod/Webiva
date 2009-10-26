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
              
  belongs_to :domain_file,
              :foreign_key => 'node_data'

  belongs_to :site_version
  validates_presence_of :site_version
              
  has_many :site_node_modifiers, :order => 'site_node_modifiers.position', :dependent => :destroy
  
  has_one :redirect_detail, :dependent => :destroy
  
  has_one :page_modifier, :class_name => 'SiteNodeModifier', :conditions => 'modifier_type IN ("P","page")'

  content_node

  acts_as_nested_set :scope => :site_version_id 
  
  attr_accessor :page_info, :closed

  # Expires the entire site when save or deleted
  expires_site

  def before_validation
    self.node_type = 'P' if self.node_type.blank?
  end

  def child_cache
    @child_cache ||= []
  end

  def child_cache=(val)
    @child_cache ||= []
    @child_cache << val
  end

  def child_cache_set(val)
    @child_cache = val
  end

  
  def menu
    if self.node_type == 'P'
      [ self ]
    elsif self.node_type == 'M'
      self.dispatcher.menu
    else
      [ self ]
    end
  end
  
  def self.find_page(page_id)
    self.find_by_id(page_id,:conditions => 'node_type="P"')
  end 
  
  
  def self.get_node_path(page_id,default_url = nil)
    nd = self.find_by_id(page_id)
    return nd.node_path if nd
    default_url
  end
  
  def self.node_path(page_id,default_url=nil)
    self.get_node_path(page_id,default_url)
  end


  def add_modifier(type)
    returning md = self.site_node_modifiers.create(:modifier_type => type) do
      md.move_to_top
    end
  end

  def add_subpage(title,type = 'P')
    nd = SiteNode.create(:title => title,:site_version_id => self.site_version_id,:node_type => type)
    nd.move_to_child_of(self) if nd.id
    nd
  end
  
  def create_temporary_revision(revision_id)
    rev = self.page_revisions.find_by_id(revision_id)
    return nil unless rev
    rev.create_temporary
  end

 
  
  def active_revision(language)
    self.page_revisions.find(:first,:conditions => 'revision_type="real" AND active=1', :order => "language='#{language}' DESC,revision DESC")
  end
  
  def visible_revision(language)
    self.page_revisions.find(:first,:conditions => 'active=1 AND revision_type="real"', :order => "language='#{language}' DESC,revision DESC")
  end
  
  def self.get_page(page_id,usr,action = 'view')
  
    nd = SiteNode.find(:first,:conditions => ['id=? AND node_type IN("P","F")',page_id])
    
    if(nd && nd.verify_node_access(usr,action))
      nd
    else
      nil
    end
  end
  
  def language_revisions(languages)
    languages.collect do |lang|
      [ lang,
        self.page_revisions.find(:first,:conditions => ['language=? AND revision_type="real"',lang], :order => 'active DESC, revision DESC')
      ]
    end
  end
  
  def active_revisions
    self.page_revisions.find(:all,:conditions => ['active=?',true], :order => 'language')
  end
  
  def domain_module_info
    if(self.node_type == 'M')
      return DomainModule.get_module_info(self.module_name,self.domain)
    else
      raise 'Not a Domain Module'
    end
  end
  
  
  def verify_node_access(usr, action = 'view')
    case self.node_type
    when 'L'
      return true
    end
    
    unless self.parent.nil?
      return self.parent.verify_node_access(usr,action)
    else
      return true
    end          
  
  end
  
  def node_path
    if self.node_type == 'R'
      "Domain"
    else
      super
    end
  end
  
  def page_type
    "page"
  end
  
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
  
  def self.page_options(include_root = false)
    node_type = include_root ? 'node_type IN("P","R","M","J")' : 'node_type IN ("P","M","J")'
    SiteNode.find(:all,:conditions => node_type,
                  :order => 'lft').collect do |page|
      [ page.node_type != 'R' ? page.node_path : include_root ,page.id ]
    end
  end
  
  def self.module_options(mod)
    SiteNode.find(:all,:conditions => [ 'module_name = ? AND node_type = "M" ',mod],
                  :order => 'node_path').collect do |page|
      [ page.node_path + " (Module)".t ,page.id ]
    end
  end
  
  
  def dispatcher_class
    "#{module_namespace.camelcase}::#{options_action.camelcase}Dispatcher".constantize
  end
  
  def dispatcher
    dispatcher_class.new(self)
  end
  
  def module_namespace
    self.module_name[1..-1].split("/")[0]
  end
  
  def options_controller
    "/" + self.module_name[1..-1].split("/")[0] + "/admin"
  end
  
  def options_action
    self.module_name[1..-1].split("/")[1]
  end

  

  def self.update_paragraph_links(old_path,new_path)
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
  
  def duplicate!(parent)
    atr = self.attributes
    atr.delete(lft)
    atr.delete(rgt)
    nd = SiteNode.new(atr)
    nd.title += '_copy'

#    nd.parent_id = parent_id
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
  
  protected
  
  def after_create
    if self.node_type == 'P'
      self.page_revisions.create( :language => Configuration.languages[0], :revision => '0.01', :active => 1 )
      self.page_revisions[0].page_paragraphs.create(:display_type => 'html', :zone_idx => 1 )
    elsif self.node_type == 'J'
      redirect_detail = self.create_redirect_detail(:redirect_type => 'site_node')
    elsif self.node_type == 'M'
      self.page_revisions.create( :language => Configuration.languages[0], :revision => '0.01', :active => 1 )
    end
    
    self.site_node_modifiers.create(:modifier_type => 'page')
  end
  
  def before_save
    node_path = ''
    if self.parent && self.parent.node_path && self.parent.node_type == 'P'
      node_path = self.parent.node_path
    end
    
	unless node_path[-1..-1] == '/'
		node_path += '/'
	end
	
	node_path +=  self.title.to_s
    
    self.node_path = node_path
    self.node_level = self.parent ?  self.parent.node_level.to_i + 1 : 0
    
  end
  
  def after_save
    unless self.frozen?
      if self.children.length > 0
        self.children.each do |child|
          child.save unless child.frozen?
        end
      end
    end
  end

end
