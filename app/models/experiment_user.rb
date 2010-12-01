
class ExperimentUser < DomainModel
  belongs_to :experiment_version
  belongs_to :experiment
  belongs_to :end_user
  belongs_to :domain_log_visitor

  validates_presence_of :domain_log_visitor_id
  validates_presence_of :language
  validates_presence_of :experiment_id
  validates_presence_of :experiment_version_id

  def success!
    self.update_attribute :success, true
  end
end
