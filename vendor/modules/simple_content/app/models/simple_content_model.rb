
class SimpleContentModel < DomainModel
  validates_presence_of :name
  validates_uniqueness_of :name

  serialize :fields

 def validate
    self.errors.add_to_base('Invalid options') unless self.content_model.valid?
  end

  def content_model_fields
    self.content_model.content_model_fields
  end

  def content_model_fields=(fields)
    self.content_model.content_model_fields = fields
  end

  def content_model
    @content_model ||= ContentHashModel.new(self.fields)
  end

  def before_save
    self.fields = self.content_model.to_a
  end
end
