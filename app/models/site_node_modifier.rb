# Copyright (C) 2009 Pascal Rettig.

class SiteNodeModifier < DomainModel
  
  acts_as_list :column => :position,
               :scope => :site_node_id
  
  belongs_to :site_node
  
  serialize :modifier_data

  has_many :page_revisions, :dependent => :destroy, :order => "revision DESC, language", 
  				:as => :revision_container

  has_many :ordered_revisions, :dependent => :destroy, :order => "revision DESC, page_revisions.id DESC", 
  				:as => :revision_container, :class_name => 'PageRevision'

  include SiteAuthorizationEngine::Target
  access_control :access

  attr_accessor :created_by_id, :copying
 
  def before_create #:nodoc:
    return if @copying
    
    if opts = self.modifier_options
      opts.initial_options
      self.modifier_data = opts.to_hash
    end
  end

  def new_revision
    rv = self.ordered_revisions.first.create_temporary
    yield rv
    rv.make_real
    rv
  end

  # Returns the name of the modifier class
  def modifier_options_class_name(full=true)
    (full ? "SiteNodeModifier::" : "") + self.modifier_type.camelcase + "ModifierOptions" 
  end

  def modifier_options
    if SiteNodeModifier.const_defined?(modifier_options_class_name(false))
      modifier_options_class_name.constantize.new(self.modifier_data)
    else
      nil
    end
  end

  def options
    @options ||= self.modifier_options
  end

  def self.find_page(page_id)
    self.find_by_id(page_id)
  end 
  
  def create_temporary_revision(revision_id)
    rev = self.page_revisions.find_by_id(revision_id)
    return nil unless rev
    rev.create_temporary
  end


  def after_create
    return if @copying

    if self.modifier_type == 'F' || self.modifier_type == 'framework'
      self.page_revisions.create( :language => Configuration.languages[0], :revision => '0.01' , :active => true, :created_by_id => self.created_by_id )
    end
  end
  
  def page_type
    'framework'
  end
  
  def node_path
    self.site_node.node_path
  end 
  
  def language_revisions(languages)
    languages.collect do |lang|
      [ lang,
        self.page_revisions.find(:first,:conditions => ['language=? AND revision_type="real"',lang], :order => 'active DESC, revision DESC'),
        self.page_revisions.find(:first,:conditions => ['language=? AND revision_type="real"',lang], :order => 'revision DESC')
      ]
    end
  end

  @@legacy_modifier_hash = {
    'L' => 'lock',
    'P' => 'page',
    'F' => 'framework',
    'E' => 'edit',
    'T' => 'template',
    'S' => 'ssl',
    'D' => 'domain'
  }

  def modifier_type
    type = self.read_attribute(:modifier_type)
    if type.length == 1
      @@legacy_modifier_hash[type]
    else
      type
    end
  end

  def before_save
    self.modifier_data = @options.to_hash if @options
  end

  private

  def modifier_parts
    return @modifier_parts if @modifier_parts
    @modifier_parts = self.modifier_type.split('/')
    if @modifier_parts.length==1
      @modifier_parts = [ nil, @modifier_parts[0] ]
    end
    @modifier_parts
  end

  public

  def modifier_module
    return modifier_parts[0]
  end

  def modifier_module_instance
    @modifier_module_instance ||= self.modifier_module.classify.new(self)
  end

  def apply_modifier!(engine,page_information)
    if(self.modifier_module)
      modifier_module_instance.send('apply_modifier_#{self.modifier_parts[1]}!',engine,page_information)
    else
      self.send("apply_modifier_#{self.modifier_type}!",engine,page_information)
    end
  end
    
  
  # Return either:
  # :locked => Not Permitted
  # :unlocked => Permitted, given other locks permit
  # :full => Permitted regardless of other locks
  def access(user)
    self.modifier_data ||= {}
    if(self.modifier_type == 'L' || self.modifier_type == 'lock')
      rl = user.has_role?('access',self)
      if self.modifier_data[:access_control] == 'unlock'
        if !rl 
          return self.modifier_data[:options].include?('override') ? :full : :unlocked
        else
          return :locked
        end
      elsif self.modifier_data[:access_control] == 'lock'
        if rl 
          return self.modifier_data[:options].include?('override') ? :full : :unlocked
        else
          return :locked
        end
      else
        return :locked
      end
    else
      raise 'Not a Lock Modifier'
    end
  end
  
    
  class TemplateModifierOptions < HashModel
    validates_presence_of :template_id
    validates_presence_of :clear_frameworks 
  
    attributes :template_id => nil, :clear_frameworks => 'no'

    def initial_options
      tpl = SiteTemplate.find(:first)
      self.template_id = tpl.id if tpl
    end
  end
  	
  class LockModifierOptions < HashModel
    validates_presence_of :access_control, :options, :redirect

    integer_options :redirect
    
    default_options :access_control => 'lock', :options => nil, :redirect => nil

    def initial_options
    end
  end
  
  class DomainModifierOptions < HashModel
    validates_presence_of :limit_to_domain
    
    default_options :limit_to_domain => ''

    def initial_options
    end

  end

  def active_language_revision(language)
    # Get the first real, active revisions from this framework that's available
    self.page_revisions.find(:first,
                             :conditions => "revision_type = 'real' AND active=1",
                             :order => "language=#{PageRevision.quote_value(language)} DESC"
                            )

  end

  def copy_live_revisions(mod)
    mod.page_revisions.find(:all, :conditions => {:revision_type => 'real', :active => true}).each do |rev|
      tmp_rev = rev.create_temporary
      tmp_rev.revision_container = self
      tmp_rev.save
      tmp_rev.make_real
    end
  end

  def fix_paragraph_options(from_version, to_version, opts={})
    self.page_revisions.find(:all, :conditions => {:revision_type => 'real', :active => true}).each { |rev| rev.fix_paragraph_options(from_version, to_version, opts) }
  end

  protected

  def apply_modifier_template!(engine,page_information)
    if self.modifier_data.is_a?(Hash)   
      tpl = SiteTemplate.find_by_id(self.modifier_data[:template_id] || 0)
      if tpl 
        unless page_information.site_template_id
          page_information[:site_template_id] = tpl.id
          # Save the template so we don't have to go for it again
          engine.active_template = tpl 
        end
        # See if this template change clears all the framework elements or not
        if self.modifier_data[:clear_frameworks] == 'yes'
          tpl.site_template_zones.each do |zn|
           page_information.zone_clears[zn.position] = true
          end
        end
      end
    end
  end


  def apply_modifier_lock!(engine,page_information)
    # For Locks, just add the lock to the beginning of the list   
    page_information.locks.unshift(self.attributes)
  end

  def apply_modifier_ssl!(engine,page_information)
    # For SSL, just set the  page_information to SSL
    page_information[:ssl] = true
  end

  def apply_modifier_domain!(engine,page_information)
    page_information[:domain] = self.modifier_data[:limit_to_domain] unless page_information[:domain]
  end


  def apply_modifier_framework!(engine,page_information)
    rev = active_language_revision(engine.language)
       # If there's a valid revision     
    if rev
      
      # Use this as the revision, unless we have a one already
      engine.revision = rev unless engine.revision
      (rev.variables||{}).each do |var,value|
        engine.revision.display_variables[var] = value if engine.revision.display_variables[var].blank?
      end
      
      # Go through the paragraphs in reverse order (as each is added to the beginning of the list)
      rev.page_paragraphs.reverse_each do |para|
        # Mark this para as a framework paragraph
        para.framework=true   
        
        page_information.zone_paragraphs[para.zone_idx] ||= []
        # for element, locks, indivate that this zone is locked for further additions
        # Unless we have already cleared everything
        if(para.display_type == 'lock' && !page_information.zone_clears[para.zone_idx])
          page_information.zone_locks[para.zone_idx] = true
          # For element clears, if we don't already have a clear, set the zone as cleared
        elsif (para.display_type == 'clear')
          if !page_information.zone_clears[para.zone_idx]
            page_information.zone_clears[para.zone_idx] = rev.id
            page_information.zone_locks[para.zone_idx] = false
          else 
            page_information.zone_clears[para.zone_idx] = true
          end
        end
        
        # If this zone has been cleared already
        if page_information.zone_clears[para.zone_idx] && page_information.zone_clears[para.zone_idx] != rev.id
          # then don't add the paragraph
          if engine.mode == 'edit' && page_information.zone_clears[para.zone_idx] != true
            # Unless we are editing, then mark it as hidden, as long as there hasnt been a second reason to clear
            para.hidden = true
            page_information.zone_paragraphs[para.zone_idx].unshift(para)
          end
        else 
          page_information.zone_paragraphs[para.zone_idx].unshift(para)
        end
      end
    end
  end


  
  
end
