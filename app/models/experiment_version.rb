
class ExperimentVersion < DomainModel
  belongs_to :experiment
  has_many :experiment_users, :dependent => :destroy
  has_many :successful_users, :conditions => 'success=1', :class_name => 'ExperimentUser'

  validates_presence_of :language
  validates_presence_of :revision
  validates_presence_of :weight
  validates_presence_of :experiment_id

  def title(opts={})
    return @title if @title
    return @title = self.revision.to_s unless self.page_revision
    @title = "#{self.revision} #{self.page_revision.version_name}"
    @title = "#{self.page_revision.active? ? '*' : ''} #{@title}" unless opts[:name_only]
    @title
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

  def after_save
    return unless self.page_revision && self.experiment

    if self.experiment.finished? || ! self.experiment.same_page?
      self.remove_experiment_conversion_webform_trigger self.page_revision
      self.remove_experiment_conversion_paragraph self.page_revision
    elsif self.experiment.same_page?
      self.add_experiment_conversion_paragraph self.page_revision, 'manual'
      self.add_experiment_conversion_webform_trigger self.page_revision if self.experiment.webform_conversion
    end
  end

  def before_destroy
    return unless self.page_revision

    self.remove_experiment_conversion_webform_trigger self.page_revision
    self.remove_experiment_conversion_paragraph self.page_revision
  end

  def add_experiment_conversion_webform_trigger(revision)
    revision.page_paragraphs.find(:all, :conditions => {:display_type => 'form', :display_module => '/webform/page'}).find do |para|
      exp_ta = para.triggered_actions.find(:all, :conditions => {:action_type => 'experiment', :action_trigger => 'submitted'}).detect do |ta|
        ta.data[:experiment_id] == self.experiment_id
      end

      unless exp_ta
        exp_ta = para.triggered_actions.create :name => 'Experiment conversion', :action_type => 'experiment', :action_trigger => 'submitted', :action_module => 'trigger/core_trigger', :comitted => true, :data => {:experiment_id => self.experiment_id}
        para.update_action_count = para.triggered_actions.count(:all,:conditions => 'action_trigger != "view"')
        para.save
      end
    end
  end

  def remove_experiment_conversion_webform_trigger(revision)
    revision.page_paragraphs.find(:all, :conditions => {:display_type => 'form', :display_module => '/webform/page'}).find do |para|
      para.triggered_actions.find(:all, :conditions => {:action_type => 'experiment', :action_trigger => 'submitted'}).each do |ta|
        if ta.data[:experiment_id] == self.experiment_id
          ta.destroy
          para.update_action_count = para.triggered_actions.count(:all,:conditions => 'action_trigger != "view"')
          para.save
        end
      end
    end
  end

  def add_experiment_conversion_paragraph(revision, experiment_type='manual')
    return if self.has_experiment_conversion_paragraph?(revision)

    exp_para = revision.page_paragraphs.find(:all, :conditions => {:display_type => 'experiment', :display_module => '/editor/action'}).find do |para|
      para.data[:experiment_id] == self.experiment_id
    end

    unless exp_para
      exp_para = revision.add_paragraph('/editor/action', 'experiment', {:experiment_id => self.experiment_id, :type => experiment_type})
      exp_para.save
    end
  end

  def remove_experiment_conversion_paragraph(revision)
    return unless self.has_experiment_conversion_paragraph?(revision)
    revision.page_paragraphs.find(:all, :conditions => {:display_type => 'experiment', :display_module => '/editor/action'}).each do |para|
      para.destroy if para.data[:experiment_id] == self.experiment_id
    end
  end

  def has_experiment_conversion_paragraph?(revision)
    revision.page_paragraphs.find(:all, :conditions => {:display_type => 'experiment', :display_module => '/editor/action'}).find do |para|
      para.data[:experiment_id] == self.experiment_id
    end
  end
end

