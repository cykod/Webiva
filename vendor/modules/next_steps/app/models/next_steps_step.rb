# create_table :next_steps_steps, :force => true do |t|
#   t.string :action_text, :description_text, :page
#   t.integer :document_id
#   t.timestamps
# end
class NextStepsStep < DomainModel
  has_many :next_steps_views, :foreign_key => :next_steps_step_id_1
  has_many :next_steps_views, :foreign_key => :next_steps_step_id_2
  has_many :next_steps_views, :foreign_key => :next_steps_step_id_3
  
  validates_presence_of :action_text, :description_text
  
  def validate
    if document_id.nil? && page.empty?
      errors.add_to_base("You need to enter either a page link or a document.")
    end
  end
end
