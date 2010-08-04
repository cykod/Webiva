# Copyright (C) 2009 Pascal Rettig.

class SiteFeature < DomainModel
  belongs_to :site_template
  serialize :options
  
  validates_presence_of :name, :feature_type
  
  belongs_to :admin_user, :class_name => 'EndUser', :foreign_key => :admin_user_id
  
  belongs_to :image_folder, :class_name => 'DomainFile', :foreign_key => 'image_folder_id'
  
  attr_accessor :validate_xml
  
  include SiteTemplate::ParsingMethods
  
  track_editor_changes
  
  def validate
    if self.validate_xml
      validator = Util::HtmlValidator.new(self.body)
      if !validator.valid?
        self.errors.add(:body," is not valid XML and has one or more errors:\n " + validator.errors.join(",\n "))
      end
    end
  end
  
  def domain_file
    self.image_folder ? self.image_folder : (self.site_template ? self.site_template.domain_file : nil )
  end
  

  def before_save
    self.body_html = replace_images(self.body.to_s)
    self.rendered_css = replace_images(self.css.to_s)
  end

  def self.options(type)
    [ [ 'Default'.t, '' ] ] +
    self.find(:all, :conditions => ['feature_type=?',type.to_s]).collect do |feat|
      [ feat.name, feat.id ]
    end 
  end
  
  
  def self.create_default_feature(feature_type)
    SiteFeature.create(:feature_type => feature_type.to_s, :body => self.default_feature(feature_type),:name => feature_type.to_s.humanize)
  end
  
  def self.default_feature(feature_type)
    feature_type = feature_type.to_s
    features = ParagraphRenderer.get_editor_features + ParagraphRenderer.get_component_features + ContentPublication.get_publication_features
    
    features.each do |feature|
      if feature[1] == feature_type
        if feature[2].is_a?(Integer)
          pub = ContentPublication.find(feature[2])
          feature_data = pub.default_feature
          return feature_data
        else
          cls = feature[2].constantize
          return cls.send("get_default_feature_#{feature_type}")
        end
      end
    end
  end
  
  def feature_details
   features = ParagraphRenderer.get_editor_features + ParagraphRenderer.get_component_features + ContentPublication.get_publication_features
   features.each do |feature|
      if feature[1] == self.feature_type
        if feature[2].is_a?(String)
          return [ feature[0],feature[1] + "_feature",feature[2].constantize]
        elsif feature[2].is_a?(Integer)
          pub = ContentPublication.find_by_id(feature[2])
          return [ feature[0],pub.feature_name + "_feature",pub.renderer_class, pub ]
        end
      end
    end
    return nil
  end
  

  def self.single_feature_type_hash(site_template_id,feature_type,options = {})
    features = []
    feature_type = feature_type.to_s
    if site_template_id 
      conditions = { :site_template_id => site_template_id, :feature_type => feature_type }
    else
      conditions = [ 'site_template_id IS NULL and feature_type = ?',feature_type ]
    end
    SiteFeature.find(:all,:select => 'id,site_template_id,name,feature_type',:conditions => conditions).map do |feature|
      features << [ feature.name, feature.id ]
    end

    if options[:include_all] && site_template_id
      features +=  self.single_feature_type_hash(nil,feature_type)
    end

    features
  end
  
  def self.feature_type_hash()
    features = {}
    SiteFeature.find(:all,:select => 'id,site_template_id,name,feature_type').map do |feature|
      features[feature.site_template_id] ||= {}
      features[feature.site_template_id][feature.feature_type] ||= []
      features[feature.site_template_id][feature.feature_type] << [ feature.name, feature.id ]
    end
    
    features
  end
  
  def style_details(override = true)
    css = override ?  replace_images(self.css) :  self.rendered_css
    Util::CssParser.parse_full(css)
  end  

  def export_to_bundle(bundler)
    details = self.feature_details
    return nil if !details || details.size == 4 # ContentPublication feature

    module_name = details[2].to_s.underscore.split('/')[0]
    (bundler.modules << module_name) if module_name != 'editor'
    bundler.add_folder(self.image_folder) if self.image_folder
    self.attributes.slice('name', 'description', 'feature_type', 'body', 'options', 'css', 'category', 'archived', 'image_folder_id', 'preprocessor')
  end

  def self.feature_hash
    paragraph_list = ParagraphController.get_editor_paragraphs + SiteModule.get_module_paragraphs.values
    output = {}

    paragraph_list.each do |para_list|
      para_list[2].each do |paragraph|
        next unless paragraph[4][0]
        output[paragraph[4][0]] ||= []
        output[paragraph[4][0]] << [ paragraph[3], paragraph[1] ]
      end
    end

    output
  end
end
