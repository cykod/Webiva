# Copyright (C) 2009 Pascal Rettig.

require 'radius'
require 'pp'

class SiteTemplate < DomainModel

  validates_presence_of :name

  has_many :site_template_zones, :dependent => :destroy, :order => :position
  has_many :site_features, :dependent => :destroy, :order => 'name'
  has_many :site_template_rendered_parts, :dependent => :destroy, :order => :idx
  belongs_to :domain_file
  
  has_many :child_templates, :class_name => "SiteTemplate", :foreign_key => :parent_id
  belongs_to :parent_template, :class_name=>"SiteTemplate", :foreign_key => :parent_id
  
  belongs_to :admin_user, :class_name => 'EndUser',:foreign_key => 'modified_by'
  
  track_editor_changes
  
  has_options :template_type, [ ['Site Template','site'], ['Mail Template','mail'] ] 
  serialize :options
  
  def self.site_template_options
    self.select_options(:conditions =>{ :template_type => 'site' })
  end
  
  def self.mail_template_options
    self.select_options(:conditions =>{ :template_type => 'mail' })
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
    SiteTemplate.create(:name => 'Default Template'.t,:template_html => "<cms:zone name='Main'/>") unless SiteTemplate.find(:first)
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
  	  		''
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
  
  
  # Update the associated zones and options
  def update_zones_and_options
  	  zones = []
  	  
  	  tpl = self
  	  
      parser_context =  initial_parser_context
  	  template_parser = Radius::Parser.new(parser_context, :tag_prefix => 'cms')
      
      parsing_errors = [] 
      
      begin
    	  template_parser.parse(self.style_struct)
      rescue Exception => err
        parsing_errors << ('Error Parsing Structural Styles of %s:' / self.name)  + err.to_s.t
      end
  	  
      begin
        template_parser.parse(self.style_design)
      rescue Exception =>  err
        parsing_errors << ('Error Parsing Design Styles of %s:' / self.name)  + err.to_s.t
      end
      
#  	  self.site_features.each do |feature|
#        begin
#    	  	template_parser.parse(feature.body)
#        rescue Exception =>  err
#          parsing_errors << ('Error Parsing Feature %s:' / feature.name)  + err.to_s.t
#        end
#  	  end
  	  
      begin
  	   template_parser.parse(self.template_html)
      rescue Exception => err
       parsing_errors << ('Error Parsing Template HTML of %s:' / self.name)  + err.to_s.t
      end
      
      parent_zones = parser_context.zones.clone
      
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
  	  
  	  update_zones(parent_zones)
  	  
  	  update_options(sorted_variables)
  	  
  	  update_localize(parser_context.translations);
      
      parsing_errors
  	  
  end
  
  # Get each feature it's own set of options,
  # So it doesn't have to go back to the template to render it 
  def update_feature_options(feature_id=nil)
    options = self.options
    
    parser_errors = []
    self.site_features.each do |feature|
    
      if(feature_id.blank? || feature.id == feature_id)
        opts= { :values => {},
                :localize_values => {},
                :localize => []
              }
        translations = []
        feature_context = InitialParserContext.new do |c|
          c.define_tag 'var' do |tag|
            opts[:values][tag.attr['name']] = options[:values][tag.attr['name']]
            ''
          end
          c.define_tag 'trans' do |tag|
            translations << tag.expand
            ''
          end
        end
          
        parser = Radius::Parser.new(feature_context, :tag_prefix => 'cms')
        begin      
          parser.parse(feature.body)
        rescue Exception
          ''
        end
        
        opts[:values].each do |key,def_val|
          options[:localize_values].each do |lang,lang_arr|
            opts[:localize_values][lang] ||= {}
            opts[:localize_values][lang][key] = lang_arr[key]
          end
        end
        
        opts[:localize] = translations.collect do |trans|
          (options[:localize] || []).detect do |t|
                    t[0] == trans
                  end
        end
        
        
        feature.save
      end
    end
  end
  	  
  # Save the user values for variables 
  def update_option_values(values)
  	saved_values = {}
    self.options[:options].each do |opt|
      var_name = opt[0]
      if values && values[var_name] 
        saved_values[var_name] = values[var_name] 
      elsif opt[6]
        saved_values[var_name] = opt[6]
      end
    end
    self.options[:values] = saved_values
  end
  
  
  def set_localization(localize_values,translate,translations)

    (localize_values || {}).each do |lang,values|
      self.update_localized_option_values(values,lang)
    end
    
    (translate || {}).each do |lang,translate|
      @site_template.update_language_translations(lang,
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
    self.options[:localize] = self.options[:localize].collect do |loc|
      translate.each do |idx,tr|
        if tr == loc[0]
          loc[1] ||= {}
          loc[1][lang] = translation[idx]
        end
      end
      loc
    end
 end
 
 def update_zone_order!(zone_order)
  zone_order.each_with_index do |zone_id,idx|
    unless zone_id.empty?
      self.site_template_zones.find_by_id(zone_id).update_attribute(:position,idx+1)
    end
  end
 end
  
 def localized_values(lang)
    langs = self.options[:localize_values] || {}
    langs[lang] || {}
  end
  
  def localized_options
    loc_opt = []

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
    css = override ?  replace_images(self.style_design) :  SiteTemplate.render_template_css(self.id,lang,false)
    Util::CssParser.parse_full(css)
  end
  
  def structural_style_details(lang,override = true)
    css = override ?  replace_images(self.style_struct) :  SiteTemplate.render_template_css(self.id,lang,'struct')
    Util::CssParser.parse_full(css)
  end
  
  
  # Return a list of the general style classes in the 
  # the Design Styles
  def self.css_design_styles(site_template_id,lang) 
    css = SiteTemplate.render_template_css(site_template_id,lang,false)
    Util::CssParser.parse_names(css,['classes']).sort
  end
  
  def self.css_styles(site_template_id,lang)
    css = SiteTemplate.render_template_css(site_template_id,lang,true)
    Util::CssParser.parse_names(css).sort
  end
  
  def css_id
    self.parent_id.blank? ? self.id : self.parent_id
  end
  
  def render_html(lang,&block)
     SiteTemplate.render_template_html(self.id,lang,&block)
  end
  
  def render_css(lang,all = true)
    SiteTemplate.render_css(self.id,lang,all)
  end
  
  def rendered_parts(lang,part='html')
    parts = self.site_template_rendered_parts.find(:all,
          :conditions => ['language = ? AND part=?',lang,part ])
    return parts if parts.length > 0
    SiteTemplateRenderedPart.transaction do
      SiteTemplateRenderedPart.delete_all(
          ['site_template_id= ? AND language = ?',self.id,lang])
      if create_rendered_parts(lang)
      	return rendered_parts(lang,part)
      end
    end
    return nil
    
  end
  
  def render_variable(variable,value,language)
    info = self.options[:options].find { |vr| vr[0] == variable }
    if info
      if info[5]
        value = self.options[:localize_values][variable] || self.options[:values][variable]
      elsif !value
        value = self.options[:values][variable]
      end
      case info[2]
      when 'color':
        value
      when 'image':
        img = DomainFile.find_by_id(value)
        img ? img.url : '/images/spacer.gif'
      when 'src':
        img = DomainFile.find_by_id(value)
        img ? img.url : ''
      when 'node':
        nd = SiteNode.find_by_id(value)
        nd ? nd.node_path : ''
      else
        value
      end
    else
      value.to_s
    end
  end
  
  def self.add_standard_parsing!(context,options = {})
    
    lang = options[:language]
    values = options[:values] || {}
    localize_values = options[:localize_values]
    translations = options[:localize]
    
    if localize_values
      localize_values = localize_values[lang] || {}
    else
      localize_value = {}
    end
    translations ||= []
    context.define_tag 'var' do |tag|
      if tag.attr['trans']
        # check language specific var,
        val = (localize_values[tag.attr['name']] || values[tag.attr['name']] ).to_s
        # else send normal var
      else
        # send normal var
        val = values[tag.attr['name']].to_s
      end
      case tag.attr['type'].to_s
        when 'color':
          val
        when 'image':
          img = DomainFile.find_by_id(val)
          if img
            img.url
          else
            ''
          end
        else
          val
      end
    end
    context.define_tag 'trans' do |tag|
        txt = tag.expand
        if options[:default_feature]
          txt.t
        else
           result = translations.detect do |t|
  		    t[0] == txt
  		  end
        if result
          if result[1][lang].to_s.empty?
            txt
          else
            result[1][lang]
          end
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
      
      re = Regexp.new("(['\"\(\>])images\/([a-zA-Z0-9_\\-\\/. ]+?)(['\"\<\)])" ,Regexp::IGNORECASE | Regexp::MULTILINE)
      
      parent_folder = self.domain_file
      if parent_folder
        while( mtch = re.match(body) ) 
            output_body += mtch.pre_match
            # do search by parent folder id
            pieces = mtch[2].split("/")
            folder = parent_folder
            while pieces.length > 1
              folder = parent_folder.children.find_by_name(pieces.shift)
            end
            img = folder.children.find_by_name(pieces[0]) if folder
            if img
               if self.is_a?(SiteTemplate) && self.template_type != 'site'
                output_body += mtch[1] + Configuration.domain_link(img.url()) + mtch[3]
              else
                output_body += mtch[1] + img.url() + mtch[3]
              end
            else
              output_body += mtch[1] + '/images/no_image.gif' + mtch[3]
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

  
  def create_rendered_parts(lang)
  
  	return false unless Configuration.languages.include?(lang)
  	
  	
    # find each images/, replace with actual image if it exists
    # Else replace with no_image image
    unless self.parent_id
      struct_css = replace_images(self.style_struct)
      design_css = replace_images(self.style_design)
      head_html = replace_images(self.head.to_s)
    end
    
    output_body = replace_images(self.template_html)
    
    
    body = self.template_html
  
    if self.parent_id
      values = self.parent_template.options[:values]
      localize_values = self.parent_template.options[:localize_values]
      translations = self.parent_template.options[:localize]
    else
      values = self.options[:values]
      localize_values = self.options[:localize_values]
      translations = self.options[:localize]
    end
    # get a rendering context
    parser_context = SiteTemplateContext.new()
    SiteTemplate.add_standard_parsing!(parser_context,:values => values,
                                                     :language => lang,
                                                     :localize_values => localize_values,
                                                     :localize => translations)
    
    
    parser_context.define_tag 'zone' do |tag|
        "<cms:zone:#{tag.attr['name']}>"
    end
    
    parser_context.define_tag 'var' do |tag|
        "<cms:var:#{tag.attr['name']}:#{tag.attr['type']}>"
    end
    
    parser = Radius::Parser.new(parser_context, :tag_prefix => 'cms')
    
    # parse css
    struct_css = parser.parse(struct_css)
    self.site_template_rendered_parts.create(
                  :zone_position => -1,
                  :part => 'css',
                  :body => struct_css,
                  :language => lang,
                  :idx => 1)
    # insert RenderedPart
    design_css = parser.parse(design_css)
    self.site_template_rendered_parts.create(
                  :zone_position => -1,
                  :part => 'css',
                  :body => design_css,
                  :language => lang,
                  :idx => 2)
    head_html = parser.parse(head_html)
    self.site_template_rendered_parts.create(
                  :zone_position => -1,
                  :part => 'head',
                  :body => head_html,
                  :language => lang,
                  :idx => 1
              )
                  
    # parse html
    body = parser.parse(output_body)
    
    re = Regexp.new("\<cms\:(zone|var)\:([^>]+)\>",Regexp::IGNORECASE | Regexp::MULTILINE)
    
    output_body = ''
    part_idx = 1
    while( mtch = re.match(body) ) 
        match_type = mtch[1]
        if(match_type == 'zone')
          zone_name = mtch[2]
          zone = self.site_template_zones.find_by_name(zone_name) || self.site_template_zones.create(:name => zone_name)
          self.site_template_rendered_parts.create(
                    :zone_position => zone.position,
                    :part => 'html',
                    :body => mtch.pre_match,
                    :language => lang,
                    :idx => part_idx)
        else
          vals = mtch[2].split(":")
          match_name = vals[0]
          match_type = vals[1].blank? ? 'string' : vals[1]
          self.site_template_rendered_parts.create(
                    :zone_position => -1,
                    :part => 'html',
                    :body => mtch.pre_match,
                    :language => lang,
                    :idx => part_idx,
                    :variable => match_name)
        end 
        part_idx+=1
        body = mtch.post_match
    end
    self.site_template_rendered_parts.create(
              :zone_position => -1,
              :part => 'html',
              :body => body,
              :language => lang,
              :idx => part_idx)
   	return true
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
      self.site_features.find(:all,:conditions => 'image_folder_id IS NULL').each do |feature|
        feature.save
      end
      
      self.site_features.find(:all,:conditions => 'image_folder_id IS NULL').each do |feature|
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
  			trans = exist[1] if exist[0] == loc
  		end
  		[ loc, trans ]
  	end
	self.options[:localize] = localize
  end
  
 
end
