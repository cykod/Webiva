# create_table :next_steps_steps, :force => true do |t|
#   t.string :action_text, :description_text, :page
#   t.integer :document_id
#   t.timestamps
# end
class NextStepsStep < DomainModel
  validates_presence_of :action_text, :description_text
  
  has_domain_file :document_id
  
  def validate
    if document_id.nil? && page.empty?
      errors.add_to_base("You need to enter either a page link or a document.")
    end
  end
  
  def to_s
    if action_text && description_text
      "#{action_text} | #{description_text}"
    else
      action_text || description_text
    end
  end
end
