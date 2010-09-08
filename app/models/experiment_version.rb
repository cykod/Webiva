
class ExperimentVersion < DomainModel
  belongs_to :experiment
  has_many :experiment_users, :dependent => :destroy
  has_many :successful_users, :conditions => 'success=1'

  validates_presence_of :language
  validates_presence_of :revision
  validates_presence_of :weight
  validates_presence_of :experiment_id
end

