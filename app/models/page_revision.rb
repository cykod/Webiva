# Copyright (C) 2009 Pascal Rettig.

class PageRevision < DomainModel

  belongs_to :revision_container,  :polymorphic => true
  has_many :page_paragraphs, :dependent => :destroy, :order => 'zone_idx,position'
  
  belongs_to :created_by, :class_name => 'EndUser'
  belongs_to :updated_by, :class_name => 'EndUser'
  
  belongs_to :parent_revision, :class_name => "PageRevision", :foreign_key => 'parent_revision_id'
  
  belongs_to :icon, :class_name => 'DomainFile', :foreign_key => 'icon_id'
  belongs_to :icon_hot, :class_name => 'DomainFile', :foreign_key => 'icon_hot_id'
  belongs_to :icon_disabled, :class_name => 'DomainFile', :foreign_key => 'icon_disabled_id'
  belongs_to :icon_selected, :class_name => 'DomainFile', :foreign_key => 'icon_selected_id'
  
  serialize :variables
  
  attr_accessor :paragraph_update_map
  
  def self.activate_page_revision(page,revision_id)

    active_rev = page.page_revisions.find_by_id(revision_id)

    unless active_rev.active?

      inactive_revs = page.page_revisions.find(:all, :conditions => ['language = ? AND active = 1',active_rev.language]);
      inactive_revs.each do |rev|
        rev.active = 0
        rev.save
      end

      active_rev.active = 1
      active_rev.save
      return true
    end

    return false

  end

  def display_variables
    return @display_variables if @display_variables
    @display_variables = (self.variables || {}).clone
  end

  def self.deactivate_page_revision(page,revision_id)

    active_rev = page.page_revisions.find_by_id(revision_id)

    if active_rev.active?
      active_rev.active = 0 
      active_rev.save
      return true
    end    

    return false
  end
  
  def site_template
    SiteTemplate.find(1)
  end

  def node_path
    if self.revision_container.is_a?(SiteNode)
      self.revision_container.node_path
    else
      self.revision_container.site_node.node_path
    end
  end


  def full_page_paragraphs
    if self.revision_container.is_a?(SiteNode)
      container = self.revision_container
      paras = container.full_framework_paragraphs(self.language,true)
    else
      container = self.revision_container.site_node
      paras = container.full_framework_paragraphs(self.language,false,self.revision_container.position)
    end
    paras + self.page_paragraphs
  end



  def used_images
    DomainFileInstance.find(:all,:conditions => { :target_type => 'PageParagraph', :target_id => page_paragraph_ids }, :include => :domain_file).map(&:domain_file).uniq
  end
  
  # Delete any temporary revisions
  # that are more than 2 days old
  def cleanup_temporary()
    PageRevision.find(:all,
                      :conditions => [ 'updated_at <  ? AND revision_type = "temp" AND revision_container_type=? AND revision_container_id=?',
                                        2.days.ago, self.revision_container_type,self.revision_container_id] ).each do |rev|
      rev.destroy
    end
  
  end
  
  # create a deep-copy of this revision in a new language
  def create_translation(language)
    new_revision = self.clone
    new_revision.language = language
    new_revision.revision_type = 'real'
    new_revision.active= false
    new_revision.save

    self.page_paragraphs.each do |para|
      new_para = para.clone
      new_para.page_revision_id=new_revision.id
      new_para.save
    end

    new_revision
  end


  # Create a new temporary revision
  # deep-cloning the paragraphs, and updating the paragraph connections
  # so that they point to the new paragraphs
  def create_temporary()

    # Create the new temporary revision
    new_rev = self.clone
    new_rev.revision_type='temp'
    new_rev.created_at = Time.now
    new_rev.updated_at = Time.now
    new_rev.parent_revision = self
    new_rev.variables ||= {}
    new_rev.identifier_hash = nil
    new_rev.save
    new_rev.paragraph_update_map = {}
    
    connection_map = {}
    # Go through each of the paragraphs
    self.page_paragraphs.each do |para|
      # Clone the paragraph
      new_para = para.clone
      # Update the revision
      new_para.page_revision = new_rev
      # Save to get a new paragraph id
      new_para.save
      
      new_rev.paragraph_update_map[para.id] = new_para.id
  
      # update the connection map to index by the new id
      connection_map[para.id] = new_para.id

      # if the paragraph has any actions, duplicate each of the triggered actions
      if para.view_action_count > 0 || para.update_action_count > 0
        para.triggered_actions.each do  |act|
          new_act = act.clone
          new_act.trigger = new_para
          new_act.save
        end
      end

    end

    # now go through each of the paragraphs in the new temporary revision
    new_rev.page_paragraphs.each do |para|
      # If there are any connections
      if para.connections
        # Check if we have input connections
        if para.connections[:inputs]
          # For each of the input connections
          para.connections[:inputs].each do |input_key,input|
            para.connections[:inputs][input_key][0] = connection_map[input[0]] if connection_map[input[0]]
          end
        end
        if para.connections[:outputs]
          para.connections[:outputs].each_with_index do |output,output_key|
            para.connections[:outputs][output_key][1] = connection_map[output[1]] if connection_map[output[1]]
          end
        end
        para.save
      end
    end

    
    new_rev
  end
    
    
  def get_translations
    existing = PageRevision.find(:all,:conditions => ['revision_container_type=? AND revision_container_id=? AND revision = ? AND revision_type="real"',self.revision_container_id,self.revision_container_id,self.revision],:order => 'language') || [] 
  
    revisions = {} 
    existing.each do |rev|
      revisions[rev.language] = rev
    end
    
    languages = LOCALES.keys.sort
    
    languages.collect do |lang|
      [lang, revisions[lang] ? revisions[lang] : nil ]
    end
  end
  
  def visible_languages
    existing = PageRevision.find(:all,:conditions => ['revision_container_type=? AND revision_container_id=? AND active=1 AND revision_type="real"',self.revision_container_id,self.revision_container_id],:order => 'language') || [] 
    
  end
  
  # Make this temporary revision into a real revision
  def make_real()
    container = self.revision_container
    
    PageRevision.transaction do 
      real_rev = container.page_revisions.find(:all,:conditions => [ 'revision_type="real" AND revision=? AND language=? AND id != ?', self.revision,self.language,self.id] ) if container
      if real_rev
        real_rev.each do |rev|
          rev.update_attributes(:revision_type => 'old' )
          DomainFileInstance.clear_targets('PageParagraph',rev.page_paragraph_ids)
        end
      end
      self.update_attributes( :created_at => Time.now,
                              :revision_type => 'real')
      self.page_paragraphs.map(&:regenerate_file_instances)

      self.page_paragraphs.map(&:link_canonical_type!)
    end
    if container.is_a?(SiteNode)
      container.save_content(self.created_by) 
    end
  
  end

  def get_next_version(version='minor')
    container = self.revision_container
    max_revision = container.page_revisions.find(:first,:order => 'page_revisions.revision DESC')

    if version == 'major'
      max_revision.revision.floor + 1
    elsif version == 'minor'
      max_revision.revision + 0.01
    end
  end

  def make_new_version(version = 'minor', version_name=nil)
  
    container = self.revision_container
    max_revision = container.page_revisions.find(:first,:order => 'page_revisions.revision DESC')

    if version == 'major'
      new_version = max_revision.revision.floor + 1
    elsif version == 'minor'
      new_version = max_revision.revision + 0.01
    else
      new_version = version.to_f
      PageRevision.transaction do 
        real_rev = container.page_revisions.find(:all,:conditions => [ 'revision_type="real" AND revision=? AND language=?', new_version,self.language] )
        real_rev.each do |rev|
          rev.update_attributes(:revision_type => 'old' )
        end
      end
    end
    
    self.update_attributes(:revision => new_version,
                           :version_name => version_name,
                           :active => false,
                           :revision_type => 'real',
                           :updated_at => Time.now)
  end
  
  def translation(lang)
    PageRevision.find(:first, 
                      :conditions => [ 'revision_type="real" AND revision=? AND revision_container_type=? AND revision_container_id=? AND language=?',
                                      self.revision,self.revision_container_type,self.revision_container_id, lang]
                      )
  end
  
  def translations(langs) 
    langs.collect do |lang|
      [ lang, translation(lang) ]    
    end
  end
  
  def identifier
    sprintf("%2.2f_%s",self.revision,self.language)
  end
  
  def activate
    unless self.active
      PageRevision.transaction do
        PageRevision.update_all(['active=?',false],[ 'revision != ? AND revision_container_type=? AND revision_container_id=? AND language=?',
                                        self.revision,self.revision_container_type,self.revision_container_id, self.language])
        PageRevision.update_all(['active=?',true],[ 'revision = ? AND revision_container_type=? AND revision_container_id=? AND language=?',
                                        self.revision,self.revision_container_type,self.revision_container_id, self.language])
      end
    end
  end
  
  def deactivate
      PageRevision.transaction do
        PageRevision.update_all(['active=?',false],[ 'revision = ? AND revision_container_type=? AND revision_container_id=? AND language=?',
                                        self.revision,self.revision_container_type,self.revision_container_id, self.language])
      end
  end


  # Programmatically add a paragraph to a revision
  def add_paragraph(renderer_class,name,paragraph_options={ },options={ })

    self.page_paragraphs.build(
                               :zone_idx => options[:zone] || 1,
                               :display_type => name,
                               :display_module => renderer_class,
                               :data => paragraph_options
                             )
  end
  

  def push_paragraph(renderer_class,name,paragraph_options={ },options={ })
    para = self.page_paragraphs.find(:first, :conditions => {:zone_idx => options[:zone] || 1,:display_type => name,:display_module => renderer_class}) || self.add_paragraph(renderer_class,name,paragraph_options,options)
    para.data = paragraph_options
    if block_given?
      yield para
    end
    para.save
    para
  end
  
  def fix_paragraph_options(from_version, to_version, opts={})
    self.page_paragraphs.each { |para| para.fix_paragraph_options(from_version, to_version, opts) }
  end
end
