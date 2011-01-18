# create_table :next_steps_views, :force => true do |t|
#   t.string :headline
#   t.integer :next_steps_step_id_1, :next_steps_step_id_2, :next_steps_step_id_3
#   t.timestamps
# end
class NextStepsView < DomainModel
  belongs_to :step_1, :foreign_key => 'next_steps_step_id_1', :class_name => 'NextStepsStep'
  belongs_to :step_2, :foreign_key => 'next_steps_step_id_2', :class_name => 'NextStepsStep'
  belongs_to :step_3, :foreign_key => 'next_steps_step_id_3', :class_name => 'NextStepsStep'
  
  validates_presence_of :headline
end
