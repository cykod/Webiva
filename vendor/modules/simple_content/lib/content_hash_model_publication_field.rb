
class ContentHashModelPublicationField
  attr_accessor :content_model_field, :field_type

  def initialize(field)
    self.content_model_field = field
    self.field_type = 'input'
  end

  def options
    self.content_model_field.publication_options_model
  end

  def data
    self.options.to_h
  end

  def form_field(entry,options={})
    self.content_model_field.form_field(entry,(self.data||{}).merge(:label => self.label).merge(options))
  end

  def label
    self.content_model_field.name
  end

  def required?
    self.content_model_field.required?
  end

  def content_model_field_id
    self.content_model_field.id
  end
end
