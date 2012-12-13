# Copyright (C) 2009 Pascal Rettig.

class ContentPublicationField < DomainModel
  belongs_to :content_model_field
  belongs_to :content_publication
  
#  acts_as_list :scope => :content_publication_id
  
  serialize :data
  
  has_options :field_type,
                  [ [ 'Value', 'value' ],
                    [ 'Input Field', 'input' ],
                    [ 'Preset Value', 'preset' ],
                    [ 'Dynamic Value', 'dynamic' ] ]
  
  def content_display(entry,size=:full,options={})
    if !self.content_model_field_id.blank? && self.content_model_field
      self.content_model_field.content_display(entry,size,(self.data||{}).merge(options))
    elsif !self.publication_field_module.blank?
      self.publication_module_class.send(:publication_value,self.publication_field_type.to_sym,self,entry)
    else
      nil
    end
  end

  def content_value(entry)
    if !self.content_model_field_id.blank? && self.content_model_field
      self.content_model_field.content_value(entry)
    else
      nil
    end
  end

  def data_field?
    if !self.content_model_field_id.blank? && self.content_model_field
      self.content_model_field.data_field?
    else
      nil
    end
  end

  def relation_class_name
    if !self.content_model_field_id.blank? && self.content_model_field
      self.content_model_field.relation_class_name
    else
      nil
    end
  end
  
 def form_field(entry,options={})
    if !self.content_model_field_id.blank? && self.content_model_field
      self.content_model_field.form_field(entry,(self.data||{}).merge(:label => self.label).merge(options))
    elsif !self.publication_field_module.blank?
      self.publication_module_class.send(:publication_field,self.publication_field_type.to_sym,self,entry)
    else
      nil
    end
  end
  
 def field_options(vars=nil)
    return @field_options if @field_options && !vars
    @field_options = self.content_publication.field_options(vars || self.data)

    @field_options.additional_vars(self.content_model_field.display_options_variables)

    @field_options
  end
    
  def field_options_form_elements(f)
    txt = self.content_publication.field_options_form_elements(self,f)
    txt += self.content_model_field.form_display_options(self,f).to_s if self.content_publication.form?

    txt += self.content_model_field.filter_display_options(self,f).to_s if self.content_publication.filter? && self.content_model_field.filter_variables.length > 0
    txt
  end
  
  def filter_display(opts)
    self.content_model_field.filter_display(opts)
  end
  
  def publication_module_class
    @publication_module_class  ||= self.publication_field_module.classify.constantize
  end

  def filter_options(f,name=nil,attr={})
    if self.content_model_field && self.options.filter 
      opts = (self.data||{ }).clone
      opts.delete(:filter)
      self.content_model_field.filter_options(f,name,opts.merge(attr.symbolize_keys))
    else 
      ''
    end
  end

  def required?
     self.content_model_field.required? || self.options.required
  end

  def options
    @options ||= self.content_publication.field_options(self.data)
  end

  def escaped_field
    self.content_model_field.escaped_field
  end
  
  def filter_variables
    self.content_model_field.filter_variables
  end

  def filter_names
    self.content_model_field.filter_names
  end
  
  def filter_conditions(opts={},form_options={})
    
    if !options.filter.blank?
      if options.filter_options && options.filter_options.include?('expose')
        opts= opts.merge(form_options.slice(*filter_variables))
      end
      return self.content_model_field.filter_conditions(opts,data)
    end
    nil
  end
  
  def available_dynamic_field_options
    ContentModel.dynamic_field_options(self.content_model_field.field_module,self.content_model_field.field_type)
  end
  
end
