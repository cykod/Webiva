
class Experiment < DomainModel
  attr_accessor :language, :page_revision_options

  has_many :experiment_versions, :order => :id, :dependent => :destroy
  has_many :experiment_users
  belongs_to :experiment_container, :polymorphic => true
  belongs_to :conversion_site_node, :class_name => 'SiteNode'

  validates_presence_of :name
  validates_presence_of :experiment_container_type
  validates_presence_of :experiment_container_id

  def num_versions
    @num_versions ||= self.min_versions
  end

  def num_versions=(n)
    @num_versions = n >= self.min_versions ? n : self.min_versions
  end

  def min_versions
    return @min_versions if @min_versions
    @min_versions = self.started? ? self.versions.size : 2
    @min_versions = 2 if @min_versions < 2
    @min_versions
  end

  def max_versions
    return @max_versions if @max_versions
    @max_versions = self.page_revision_options ? self.page_revision_options.size : self.min_versions
    @max_versions = self.min_versions if @max_versions < self.min_versions
    @max_versions
  end

  def finished?
    ! self.ended_at.blank? && self.ended_at <= Time.now
  end

  def started?
    self.started_at && self.started_at <= Time.now
  end

  def is_running?
    self.started? && ! self.finished?
  end

  def active?
    self.experiment_container && self.id && self.experiment_container.experiment_id == self.id
  end

  def validate
    if @versions && @versions.size > 0
      if self.total_weight != 100 && self.total_weight != 0
        self.errors.add_to_base("Weights must added up to 100")
        @versions.each { |v| v.errors.add(:weight, 'is invalid') }
      end

      @wrong_language = false
      @versions.each do |v|
        if v.language != self.language
          @versions.errors.add(:language, 'is invalid')
          @wrong_language = true
        end
      end

      self.errors.add(:language, "is invalid") if @wrong_language
    end
  end

  def start!(start_time=nil)
    start_time ||= Time.now
    self.update_attribute :started_at, start_time
  end

  def restart!(end_time=nil, opts={})
    if opts[:reset]
      self.experiment_users.delete_all
      start_time = opts[:start_time] || Time.now
      self.update_attributes :started_at => start_time, :ended_at => end_time
    else
      self.update_attribute :ended_at, end_time
    end
  end

  def end_experiment!(end_time=nil)
    end_time ||= Time.now
    self.update_attribute :ended_at, end_time
  end

  def total_weight
    self.versions.collect(&:weight).inject(0) { |sum, n| sum + n.to_i }
  end

  # returns an array of language specific versions
  def versions
    @versions ||= self.experiment_versions.find(:all, :conditions => {:language => self.language}, :order => :id)
  end

  def versions=(vers)
    @versions = []
    vers = vers.sort { |a,b| a[0].to_i <=> b[0].to_i }.collect { |v| v[1] } if vers.is_a?(Hash)
    vers.each do |ver|
      version = ver[:id] ? self.experiment_versions.find_by_id(ver[:id]) : nil
      version ||= ExperimentVersion.new(:experiment_id => self.id, :language => self.language)

      if version.id && self.is_running?
        version.attributes = ver.slice(:weight)
      else
        version.attributes = ver.slice(:weight, :revision)
      end

      @versions << version
    end

    if self.is_running?
      ids = @versions.collect(&:id)
      @versions += self.experiment_versions.find(:all, :conditions => {:language => self.language}).select { |ver| ! ids.include?(ver.id) }
    end

    @versions
  end

  def after_save
    if @versions && self.language

      unless self.is_running?
        ids = @versions.collect(&:id)
        self.experiment_versions.find(:all, :conditions => {:language => self.language}).each do |ver|
          ver.destroy unless ids.include?(ver.id)
        end
      end

      auto_set_weight = self.total_weight == 0
      weight_per_version = @versions.size > 0 ? 100 / @versions.size : 0
      left_over_weight = @versions.size > 0 ? 100 % @versions.size : 0
      @versions.each do |ver|
        ver.experiment_id = self.id
        if auto_set_weight
          ver.weight = weight_per_version
          ver.weight += 1 if left_over_weight > 0
          left_over_weight -= 1
        end
        ver.save
      end

      @versions = nil
    end
  end

  def get_user(session)
    return nil unless session[:domain_log_visitor] && session[:cms_language]
    user = self.experiment_users.find_by_domain_log_visitor_id_and_language(session[:domain_log_visitor][:id], session[:cms_language])
    user.update_attribute(:end_user_id, session[:domain_log_visitor][:end_user_id]) if user && user.end_user_id.nil? && session[:domain_log_visitor][:end_user_id]
    user
  end

  def get_version(session)
    return nil unless self.is_running?
    return nil unless session[:domain_log_visitor] && session[:cms_language]

    user = self.get_user(session)
    return user.experiment_version if user

    @versions = nil
    self.language = session[:cms_language]

    weight_sum = 0
    random_weight = rand(self.total_weight)
    version = self.versions.find do |v|
      weight_sum += v.weight
      weight_sum > random_weight
    end

    return nil unless version


    self.experiment_users.create :experiment_version_id => version.id, :domain_log_visitor_id => session[:domain_log_visitor][:id], :language => self.language, :end_user_id => session[:domain_log_visitor][:end_user_id], :domain_log_session_id => session[:domain_log_session][:id]
    version
  end

  def success!(session)
    return unless self.is_running?
    user = self.get_user(session)
    user.success! if user
  end

  def self.success!(experiment_id, session)
    return unless session[:domain_log_visitor] && session[:cms_language]
    exp = Experiment.find_by_id experiment_id
    exp.success!(session) if exp
  end
end
