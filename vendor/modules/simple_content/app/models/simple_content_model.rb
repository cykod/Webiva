
class SimpleContentModel < DomainModel
  validates_presence_of :name
  validates_uniqueness_of :name
  validate :validate_content_model
  
  serialize :fields

  before_save :update_fields
  
  def validate_content_model
    self.errors.add(:base, 'Invalid options') unless self.content_model.valid?
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

  def update_fields
    self.fields = self.content_model.to_a
  end
end
