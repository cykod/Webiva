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
  
 def form_field(entry,options={})
    if !self.content_model_field_id.blank? && self.content_model_field
      self.content_model_field.form_field(entry,(self.data||{}).merge(:label => self.label).merge(options))
    elsif !self.publication_field_module.blank?
      self.publication_module_class.send(:publication_field,self.publication_field_type.to_sym,self,entry)
    else
      nil
    end
  end
  
  def field_options
    return @field_options if @field_options
    @field_options = self.content_publication.field_options(self.data)
    @field_options.additional_vars(self.content_model_field.display_options_variables)
    
    @field_options
  end
    
  def field_options_form_elements(f)
    txt = self.content_publication.field_options_form_elements(self,f)
    txt += self.content_model_field.form_display_options(self,f) if self.content_publication.form?
    txt
  end
  
  def publication_module_class
    @publication_module_class  ||= self.publication_field_module.classify.constantize
  end

  def filter_options(f)
    if self.content_model_field && (self.data[:options] || []).include?('filter') 
      self.content_model_field.filter_options(f)
    else 
      ''
    end
  end
  
  def filter_variables
    self.content_model_field.filter_variables
  end
  
  def filter_conditions(options={})
    if (self.data[:options] || []).include?('filter')
        self.content_model_field.filter_conditions(options)
    end
  end
  
  def available_dynamic_field_options
    ContentModel.dynamic_field_options(self.content_model_field.field_module,self.content_model_field.field_type)
  end
  
end
