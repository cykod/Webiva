# Copyright (C) 2009 Pascal Rettig.

require 'radius'
require 'pp'

LESS_AVAILABLE = false

class SiteTemplate < DomainModel

  validates_presence_of :name

  has_many :site_template_zones, :dependent => :destroy, :order => :position
  has_many :site_features, :dependent => :destroy, :order => 'name'
  has_many :site_template_rendered_parts, :dependent => :destroy, :order => :idx
  belongs_to :domain_file
  
  has_many :child_templates, :class_name => "SiteTemplate", :foreign_key => :parent_id
  belongs_to :parent_template, :class_name => "SiteTemplate", :foreign_key => :parent_id
  
  belongs_to :admin_user, :class_name => 'EndUser',:foreign_key => 'modified_by'
  
  track_editor_changes
  
  has_options :template_type, [['Site Theme','site'], ['Mail Theme','mail']]

  serialize :options

  def self.site_template_options
    self.select_options(:conditions => ['template_type = "site" and parent_id IS NULL'])
  end
  
  def self.mail_template_options
    self.select_options(:conditions => 'template_type = "mail"')
  end

  class SiteTemplateContext < Radius::Context 
    def tag_missing(tag,attr,&block)
      ''
    end
  end
  
  class InitialParserContext < SiteTemplateContext
    # Make sure we expand tags even if we have a 
    # a bad tag underneat
    def render_tag(name, attributes = {}, &block)
      if name =~ /^(.+?):(.+)$/
        render_tag($1) { render_tag($2, attributes, &block) }
      else
        tag_definition_block = @definitions[qualified_tag_name(name.to_s)]
        if tag_definition_block
          stack(name, attributes, block) do |tag|
            tag_definition_block.call(tag).to_s
          end
        else
          stack(name, attributes, block) do |tag|
            tag.expand.to_s
          end
        end
      end
    end
    
    def initialize
      @variables = []
      @zones = []
      @translations = []
      super
    end

    attr_accessor :variables
    attr_accessor :zones
    attr_accessor :translations
  end

  def self.create_default_template
    SiteTemplate.create(:name => 'Default Theme'.t,:template_html => "<cms:zone name='Main'/>") unless SiteTemplate.find(:first)
  end
  
  # Override domain file setting so we can
  # update the old one if necessary
  def domain_file_id=(df_id)
    @old_domain_file_id = self.domain_file_id
    self.write_attribute(:domain_file_id,df_id)
  end

  # Make sure the updating works with setting the file as well as the id
  def domain_file=(df); self.domain_file_id=(df.id); end  

  protected

  # This initial parser context is used to find all the cms:var, cms:trans and cms:zone tags
  def initial_parser_context
    parser_context = SiteTemplate::InitialParserContext.new do |c|
      c.define_tag 'var' do |tag|
        c.variables << 
          [ tag.attr['name'], 
          tag.attr['label'] || tag.attr['name'].humanize, 
          tag.attr['type'] || 'string', 
          (tag.attr['desc'] || tag.attr['description']).to_s, 
          (tag.attr['pri'] || 100).to_i, 
          tag.attr['trans'] || false,
          tag.attr['default'] || ''
        ]
        tag.attr['default'] || ''
      end

      c.define_tag 'trans' do |tag|
        c.translations << tag.expand
      end
      
      c.define_tag 'zone' do |tag|
        c.zones << tag.attr['name']	
      end
    end  
  end
  
  public
  
  # Update the associated zones and options.
  # When cms:var, cms:zone or cms:trans tags are added to a template_html
  # this is where they are initially parsed and stored as options.
  # create_rendered_parts is where the tags are replaced with there values.
  def update_zones_and_options
    parsing_errors = [] 
    parser_context =  initial_parser_context
    template_parser = Radius::Parser.new(parser_context, :tag_prefix => 'cms')
    
    begin
      template_parser.parse(self.template_html)
    rescue Exception => err
      parsing_errors << ('Error Parsing Template HTML of %s:' / self.name)  + err.to_s.t
    end
    
    update_zones(parser_context.zones.clone)

    # if we are a child template we don't have css or children
    return parsing_errors if self.parent_id

    begin
      struct_css = template_parser.parse(self.style_struct)
      struct_css = self.class.render_with_less(struct_css)
    rescue Exception => err
      parsing_errors << ('Error Parsing Structural Styles of %s:' / self.name)  + err.to_s.t
    end
    
    begin
      design_css = template_parser.parse(self.style_design)
      design_css = self.class.render_with_less(design_css)
    rescue Exception => err
      parsing_errors << ('Error Parsing Design Styles of %s:' / self.name)  + err.to_s.t
    end
    
    self.site_features.each do |feature|
      begin
        template_parser.parse(feature.body)
      rescue Exception => err
        parsing_errors << ('Error Parsing Feature %s:' / feature.name)  + err.to_s.t
      end
    end
    
    self.child_templates.each do |child|
      begin
        template_parser.parse(child.template_html)
      rescue Exception => err
        parsing_errors << ('Error Parsing Template HTML of %s:' / child.name)  + err.to_s.t
      end
    end
    
    output_variables = []
    existing_variables = {}
    parser_context.variables.each do |var|
      if(existing_variables[var[0]])
        existing_idx = existing_variables[var[0]];
        merged_var = (0..var.length-1).collect do |idx|
          if(!output_variables[existing_idx][idx].to_s.empty?)
            output_variables[existing_idx][idx]
          else
            var[idx]
          end
        end
        output_variables[existing_idx] = merged_var
      else
        output_variables << var
        existing_variables[var[0]] = output_variables.length-1
      end
    end
    
    sorted_variables  = output_variables.sort_by do |var|
      [ var[4].to_i,var[1].to_s ]
    end

    update_options(sorted_variables)

    update_localize(parser_context.translations);
    
    parsing_errors
  end
  
  # Get each feature it's own set of options,
  # So it doesn't have to go back to the template to render it 
  def update_feature_options(feature_id=nil)
    self.site_features.each do |feature|
      if feature_id.nil? || feature_id == feature.id
        feature.options = self.options
        feature.save
      end
    end
  end
  
  # Save the user values for variables 
  def update_option_values(values)
    saved_values = {}
    self.options[:options].each do |opt|
      var_name = opt[0]
      if values && !values[var_name].blank? 
        saved_values[var_name] = values[var_name]
      elsif self.options[:values][var_name]
        saved_values[var_name] = self.options[:values][var_name]
      elsif opt[6]
        if opt[2] == 'image'
          parent = self.domain_file
          img = DomainFile.find_by_file_path(parent.file_path + "/" + opt[6]) if parent
          saved_values[var_name] = img.id if img
        else
          saved_values[var_name] = opt[6]
        end
      end
    end
    self.options[:values] = saved_values
  end

  def set_localization(localize_values,translate,translations)
    (localize_values || {}).each do |lang,values|
      self.update_localized_option_values(values,lang)
    end

    (translate || {}).each do |lang,translate|
      self.update_language_translations(lang,
                                        translate,
                                        translations[lang]
                                        )
    end
  end
  
  # Save the localized values for variables
  def update_localized_option_values(values,lang) 
    self.options[:localize_values]  ||= {}
    lang_values = self.options[:localize_values][lang] || {}
    self.options[:options].each do |opt|
      var_name = opt[0]
      if(opt[5])
        lang_values[var_name] = values[var_name].empty? ? nil : values[var_name]
      end
    end
    self.options[:localize_values][lang] = lang_values
  end
  
  def update_language_translations(lang,translate,translation)
    # options[:localize] = [ [<string to translate>, {'en' = <translated string>, 'es' => <spanish translation>, ...} ],
    #                        ... ]
    self.options[:localize] = self.options[:localize].collect do |loc|
      translate.each do |idx,tr|
        if tr.to_s.strip == loc[0].to_s.strip
          loc[1] ||= {}
          loc[1][lang] = translation[idx]
        end
      end
      loc
    end
  end
  
  def update_zone_order!(zone_order)
    pos = 1
    zone_order.each do |zone_id|
      next if zone_id.empty?

      zone = self.site_template_zones.find_by_id(zone_id)
      if zone
        zone.update_attribute(:position, pos)
        pos += 1
      end
    end
  end
  
  def localized_values(lang)
    langs = self.options[:localize_values] || {}
    langs[lang] || {}
  end
  
  def localized_options
    loc_opt = []
    self.options[:options] ||= []
    self.options[:options].each do |opt|
      if(opt[5])
        loc_opt << opt
      end
    end
    
    loc_opt
  end
  
  def self.render_template_head(site_template_id,lang)
    parts = rendered_parts(site_template_id,lang,'head')
    return '' unless parts  
    parts[0].body
  end
  
  def self.render_template_html(site_template_id,lang,&block)
    (rendered_parts(site_template_id,lang) || []).each do |part|
      yield part
    end
  end
  
  def self.render_template_css(site_template_id,lang,all = true)
    parts = rendered_parts(site_template_id,lang,'css')
    return '' unless parts
    if all.to_s == 'struct'
      parts[0].body
    elsif(all)
      parts[0].body + parts[1].body
    else
      parts[1].body
    end
  end
  
  def full_styles_hash(lang,override=true)
    styles = design_style_details(lang,override) + structural_style_details(lang,override)
    styles_hash = { }
    styles.each do |style|
      styles_hash[style[0]] = style[2].map { |elm| elm.join(':') + ";" }.join('')
    end
    styles_hash
  end
  
  # Return an array of styles from text
  def design_style_details(lang,override = true)
    css = override ?  self.parse_css(self.style_design, lang) :  SiteTemplate.render_template_css(self.id,lang,false)
    Util::CssParser.parse_full(css)
  end
  
  def structural_style_details(lang,override = true)
    css = override ?  self.parse_css(self.style_struct, lang) :  SiteTemplate.render_template_css(self.id,lang,'struct')
    Util::CssParser.parse_full(css)
  end

  # Return a list of the general style classes in the 
  # the Design Styles
  def self.css_design_styles(site_template_id,lang) 
    css = SiteTemplate.render_template_css(site_template_id,lang,false)
    Util::CssParser.parse_names(css,['classes']).sort.map { |elm| elm.to_s[1..-1] }
  end
  
  def self.css_styles(site_template_id,lang)
    css = SiteTemplate.render_template_css(site_template_id,lang,true)
    Util::CssParser.parse_names(css).sort
  end
  
  def css_id
    self.parent_id.blank? ? self.id : self.parent_id
  end
  
  def render_html(lang, &block)
    SiteTemplate.render_template_html(self.id,lang,&block)
  end
  
  def rendered_parts(lang,part='html')
    parts = self.site_template_rendered_parts.find(:all, :conditions => ['language = ? AND part = ?', lang, part])
    return parts if parts.length > 0

    # if no parts are found for a given language and type
    # remove all parts for that language and recreate the parts
    SiteTemplateRenderedPart.transaction do
      SiteTemplateRenderedPart.delete_all(['site_template_id = ? AND language = ?', self.id, lang])
      return rendered_parts(lang,part) if create_rendered_parts(lang)
    end

    nil
  end

  def real_options
    @real_options ||= self.parent_id ? self.parent_template.options : self.options
  end

  # Used to replace <cms:var> tags with there correct values in the template_html
  def render_variable(variable, value, language)
    info = self.real_options[:options].find { |vr| vr[0] == variable }
    if info
      if info[5]
        if self.real_options[:localize_values][language] && self.real_options[:localize_values][language][variable]
          value = self.real_options[:localize_values][language][variable]
        else
          value = self.options[:values][variable]
        end
      elsif !value
        value = self.real_options[:values][variable]
      end

      case info[2]
      when 'image'
        img = DomainFile.find_by_id(value)
        img ? img.image_tag : '<img src="/images/spacer.gif"/>'
      when 'src'
        img = DomainFile.find_by_id(value)
        img ? img.url : '/images/spacer.gif'
      else
        value
      end
    else
      value.to_s
    end
  end

  # Used to replace <cms:var> tags with there correct values in the style_design, style_struct and head
  def self.add_standard_parsing!(context,options = {})
    lang = options[:language]
    values = options[:values] || {}
    localize_values = options[:localize_values]
    translations = options[:localize] || []
    
    if localize_values
      localize_values = localize_values[lang] || {}
    else
      localize_value = {}
    end

    context.define_tag 'var' do |tag|
      if tag.attr['trans']
        val = (localize_values[tag.attr['name']] || values[tag.attr['name']] ).to_s
      else
        val = values[tag.attr['name']].to_s
      end

      if tag.attr['type'].to_s == 'image'
        img = DomainFile.find_by_id(val)
        val = img ? img.url : '/images/spacer.gif'
      end

      val
    end

    context.define_tag 'trans' do |tag|
      txt = tag.expand
      if options[:default_feature]
        txt.t
      else
        # check the translations for the string to translate
        result = translations.detect { |t| t[0].to_s.strip == txt.to_s.strip }

        # if we found the translations and the language has a translation use it
        if result && ! result[1][lang].to_s.empty?
          result[1][lang]
        else
          txt
        end
      end
    end
  end
  
  protected 
  
  def self.rendered_parts(site_template_id,lang,part='html')
    parts = SiteTemplateRenderedPart.find(:all,
                                          :conditions => ['site_template_id=? AND language = ? AND part=?',site_template_id,lang,part ])
    return parts if parts.length > 0
    
    self.find(site_template_id).rendered_parts(lang,part)
  end 
  
  
  module ParsingMethods
    def replace_images(body)
      
      output_body = ''
      
      re = Regexp.new("(['\"\(\>])(images|files)\/([a-zA-Z0-9_\\-\\/. ]+?)([?#'\"\<\)])" ,Regexp::IGNORECASE | Regexp::MULTILINE)
      
      parent_folder = self.domain_file
      if parent_folder
        while mtch = re.match(body)
          output_body += mtch.pre_match
          file_path = parent_folder.file_path + '/' + mtch[3]
          img = DomainFile.find_by_file_path file_path
          if img
            url = img.url
            if self.is_a?(SiteTemplate) && self.template_type != 'site' && url[0..0] == '/'
              output_body += mtch[1] + Configuration.domain_link(url) + mtch[4]
            else
              output_body += mtch[1] + url + mtch[4]
            end
          else
            output_body += mtch[1] + '/images/no_image.gif' + mtch[4]
          end
          body = mtch.post_match
        end
        output_body += body.to_s
      else
        output_body = body.to_s
      end
      
      output_body
    end
  end
  
  include SiteTemplate::ParsingMethods

  def self.render_with_less(css, opts={})
    return css unless LESS_AVAILABLE

    begin
      raise Less::SyntaxError.new("@import not supported") if css =~ /\@import/
      Less.parse(css)
    rescue Less::SyntaxError, Less::ImportError => e
      raise e unless opts[:ignore]
      css
    end
  end

  def create_standard_parser(lang)
    values = self.real_options[:values]
    localize_values = self.real_options[:localize_values]
    translations = self.real_options[:localize]

    parser_context = SiteTemplateContext.new()

    SiteTemplate.add_standard_parsing!(parser_context,:values => values,
                                       :language => lang,
                                       :localize_values => localize_values,
                                       :localize => translations)

    if block_given?
      yield parser_context
    end

    Radius::Parser.new(parser_context, :tag_prefix => 'cms')
  end

  def standard_parser(lang)
    @standard_parser ||= self.create_standard_parser(lang)
  end

  def parse_html(html, lang)
    self.standard_parser(lang).parse(replace_images(html))
  end

  def parse_css(css, lang)
    self.class.render_with_less(self.parse_html(css, lang), :ignore => true)
  end

  def create_rendered_parts(lang)
    return false unless Configuration.languages.include?(lang)

    parser = self.create_standard_parser(lang) do |parser_context|
      parser_context.define_tag 'zone' do |tag|
        "<cms:zone:#{tag.attr['name']}>"
      end

      parser_context.define_tag 'var' do |tag|
        "<cms:var:#{tag.attr['name']}:#{tag.attr['type']}>"
      end
    end
    
    body = parser.parse(self.replace_images(self.template_html))
    
    re = Regexp.new("\<cms\:(zone|var)\:([^>]+)\>", Regexp::IGNORECASE | Regexp::MULTILINE)
    
    part_idx = 1
    while mtch = re.match(body)
      match_type = mtch[1]
      if(match_type == 'zone')
        zone_name = mtch[2]
        zone = self.site_template_zones.find_by_name(zone_name) || self.site_template_zones.create(:name => zone_name)
        self.site_template_rendered_parts.create(:zone_position => zone.position,
                                                 :part => 'html',
                                                 :body => mtch.pre_match,
                                                 :language => lang,
                                                 :idx => part_idx)
      else
        vals = mtch[2].split(":")
        match_name = vals[0]
        match_type = vals[1].blank? ? 'string' : vals[1]
        self.site_template_rendered_parts.create(:zone_position => -1,
                                                 :part => 'html',
                                                 :body => mtch.pre_match,
                                                 :language => lang,
                                                 :idx => part_idx,
                                                 :variable => match_name)
      end
      part_idx += 1
      body = mtch.post_match
    end

    self.site_template_rendered_parts.create(:zone_position => -1,
                                             :part => 'html',
                                             :body => body,
                                             :language => lang,
                                             :idx => part_idx)

    unless self.parent_id
      @standard_parser = nil

      self.site_template_rendered_parts.create(:zone_position => -1,
                                               :part => 'css',
                                               :body => self.parse_css(self.style_struct, lang),
                                               :language => lang,
                                               :idx => 1)

      self.site_template_rendered_parts.create(:zone_position => -1,
                                               :part => 'css',
                                               :body => self.parse_css(self.style_design, lang),
                                               :language => lang,
                                               :idx => 2)

      self.site_template_rendered_parts.create(:zone_position => -1,
                                               :part => 'head',
                                               :body => self.parse_html(self.head.to_s, lang),
                                               :language => lang,
                                               :idx => 1
                                               )
    end

    true
  end
  
  def update_zones(zones)
    existing_zones = self.site_template_zones.to_a

    # Get rid of any zones no longer in the template
    existing_zones.each do |existing_zone|
      if zones.include?(existing_zone.name)
        zones.delete(existing_zone.name)
      else
        existing_zone.destroy
      end
    end

    # And add any new ones to the end
    zones.each do |zone|
      self.site_template_zones.create(:name => zone)
    end
  end
  
  def update_options(opts)
    self.options ||= {}
    self.options[:options] = opts
  end
  
  def before_create
    self.head ||= ''
    self.options ||= {}
    self.options = { :options => self.options[:options] || [],
      :presets => self.options[:presets] || [],
      :values => self.options[:values] || {},
      :localize_values => self.options[:localize_values] || {},
      :localize => self.options[:localize] || []
    }
  end
  
  def after_save
    self.site_template_rendered_parts.clear
    
    if self.domain_file_id != @old_domain_file_id
      old_fold = DomainFile.find_by_id(@old_domain_file_id) if @old_domain_file_id
      old_fold.update_attribute(:special,'') if old_fold 
      
      new_fold = DomainFile.find_by_id(self.domain_file_id)
      new_fold.update_attribute(:special,'template') if new_fold 
      
      # Resave all the child site features that don't have their own set image folder
      self.site_features.each do |feature|
        feature.options = self.options
        feature.save
      end
    end    
  end
  
  def update_localize(translate)
    # Remove duplicates
    translate.uniq!
    cur = self.options[:localize] || []
    
    
    localize = translate.collect do |loc|
      trans = {}
      cur.each do |exist|
        trans = exist[1] if exist[0].to_s.strip == loc.to_s.strip
      end
      [ loc, trans ]
    end
    self.options[:localize] = localize
  end
  
  public

  def export_to_bundle(bundler)
    bundler.add_folder(self.domain_file) if self.domain_file

    data = self.attributes.slice('name', 'description', 'template_html', 'style_struct', 'style_design', 'template_type', 'head', 'doctype', 'partial', 'lightweight', 'preprocessor', 'domain_file_id')
    data['options'] = self.options.merge(:values => {}, :localize_values => {})
    data['features'] = self.site_features.collect { |feature| feature.export_to_bundle(bundler) }.compact
    data['children'] = self.child_templates.collect { |child| child.export_to_bundle(bundler) }
    data['zones'] = self.site_template_zones.collect { |zone| zone.name }
    data
  end

  def self.import_bundle(bundler, data, opts={})
    # Get the new images folder
    domain_file_id = data['domain_file_id'] ? bundler.get_new_input_id(DomainFile, data['domain_file_id']) : nil

    # Create the site template
    site_template = nil
    site_template = SiteTemplate.find_by_parent_id_and_name(data['parent_id'], data['name']) if opts[:replace_same]
    site_template ||= SiteTemplate.new(:parent_id => data['parent_id'], :name => data['name'])
    site_template.update_attributes data.slice('description', 'template_html', 'options', 'style_struct', 'style_design', 'template_type', 'head', 'doctype', 'partial', 'lightweight', 'preprocessor').merge('domain_file_id' => domain_file_id)

    data['id'] = site_template.id

    # Create the zones
    site_template.site_template_zones.clear
    data['zones'].each_with_index do |name, idx|
      site_template.site_template_zones.create :name => name, :position => (idx+1)
    end

    # Create the features
    site_template.site_features.clear
    data['features'].each do |feature|
      image_folder_id = feature['image_folder_id'] ? bundler.get_new_input_id(DomainFile, feature['image_folder_id']) : nil
      site_template.site_features.create feature.merge('image_folder_id' => image_folder_id)
    end

    # Create the templates children
    data['children'].each do |child|
      child['parent_id'] = site_template.id
      SiteTemplate.import_bundle bundler, child, opts
    end

    site_template = SiteTemplate.find site_template.id
    site_template.options[:values] = {}
    site_template.update_option_values nil
    site_template.save

    site_template
  end

  def apply_to_site(version, opts={})
    version.root_node.push_modifier('template') do |mod|
      mod.options.template_id = self.id
      mod.move_to_top
      mod.save
    end

    # Apply theme features to existing paragraphs
    if opts[:features]
      feature_hash = SiteFeature.feature_hash

      revisions = {}
      self.site_features.each do |feature|
        next unless feature_hash[feature.feature_type]
        feature_hash[feature.feature_type].each do |info|
          PageParagraph.live_paragraphs.with_feature(*info).group_by(&:page_revision_id).each do |page_revision_id, paragraphs|
            revisions[page_revision_id] ||= []
            revisions[page_revision_id] += paragraphs.map { |para| [para.identity_hash, feature.id] }
          end
        end
      end

      revisions.each do |page_revision_id, paragraphs|
        rv = PageRevision.find(page_revision_id).create_temporary
        paragraphs.each do |info|
          para = rv.page_paragraphs.detect { |p| p.identity_hash == info[0] }
          para.update_attribute :site_feature_id, info[1]
        end
        rv.make_real
      end
    end

    DomainModel.expire_site
  end
end
