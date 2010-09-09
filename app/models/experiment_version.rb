
class ExperimentVersion < DomainModel
  belongs_to :experiment
  has_many :experiment_users, :dependent => :destroy
  has_many :successful_users, :conditions => 'success=1', :class_name => 'ExperimentUser'

  validates_presence_of :language
  validates_presence_of :revision
  validates_presence_of :weight
  validates_presence_of :experiment_id

  def title
    return @title if @title
    return @title = self.revision.to_s unless self.page_revision
    @title = "#{self.page_revision.active? ? '*' : ''} #{self.revision} #{self.page_revision.version_name}"
  end

  def num_visits
    self.experiment_users.count
  end

  def num_conversions
    self.successful_users.count
  end

  def success_percent
    return 0 unless self.num_visits > 0
    (self.num_conversions.to_f / self.num_visits.to_f * 100.0).to_i
  end

  def page_revision
    return @page_revision if @page_revision
    return nil unless self.experiment && self.experiment.experiment_container
    @page_revision = self.experiment.experiment_container.page_revisions.first :conditions => {:revision => self.revision, :language => self.language, :revision_type => 'real'}
  end
end

