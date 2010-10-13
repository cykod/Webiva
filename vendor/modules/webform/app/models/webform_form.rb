
class WebformForm < DomainModel
  validates_presence_of :name
  validates_uniqueness_of :name

  has_many :webform_form_results, :dependent => :delete_all

  serialize :fields
  serialize :features

  cached_content

  def validate
    self.errors.add_to_base('Invalid options') unless self.content_model.valid?
  end

  def content_model_fields
    self.content_model.content_model_fields
  end

  def content_model_fields=(fields)
    self.content_model.content_model_fields = fields
  end

  def content_model_features
    self.content_model.content_model_features
  end

  def content_model_features=(features)
    self.content_model.content_model_features = features
  end

  def content_model
    @content_model ||= ContentHashModel.new(self.fields, self.features)
  end

  def before_save
    self.fields = self.content_model.to_a
    self.features = self.content_model.features
  end

  def webform_features(result)
    self.content_model_features.each do |feature|
      feature.webform(self, result) if feature.respond_to?('webform')
    end
  end

  def self.get_webform_handler_options(initialized=false)
    self.get_handler_options(:content, :feature) do |handler, cls|
      info = cls.content_feature_handler_info
      info[:callbacks] && info[:callbacks].include?(:webform) ? true : false
    end
  end

  def total_results
    self.stats[:total]
  end

  def new_results
    self.stats[:new]
  end

  def past_10_days
    (0..9).collect do |d|
      date = d.days.ago.strftime('%Y-%m-%d')
      self.stats[:submitted_forms][date] ? self.stats[:submitted_forms][date] : 0
    end
  end

  def stats
    @stats ||= self.calculate_stats
  end

  def calculate_stats(from=nil, to=nil)
    to = Time.now unless to
    from = to - 10.days unless from

    cache_key = "stats_#{from.strftime('%m/%d/%Y')}_#{to.strftime('%m/%d/%Y')}"
    results = cache_fetch(cache_key)
    unless results
      results = {
        :total => WebformFormResult.posted_before(to).count(:all, :conditions => {:webform_form_id => self.id}),
        :new => WebformFormResult.posted_before(to).count(:all, :conditions => {:webform_form_id => self.id, :reviewed => false}),
        :submitted_forms => WebformFormResult.posted_between(from, to).count(:all, :group => 'DATE(posted_at)', :order => 'DATE(posted_at)', :conditions => {:webform_form_id => self.id})
      }

      cache_put(cache_key, results)
    end

    results
  end

  def calculate_result_stats
    return @form_results if @form_results

    @form_results = {}

    options_fields = []
    boolean_fields = []
    self.content_model_fields.each do |field|
      if field.field_options['options'] && field.field_options['options'].length > 0
        options_fields << field.id
        @form_results[field.id] = {}
        field.module_class.available_options.each { |opt| @form_results[field.id][opt[1]] = 0 }
      elsif field.representation == :boolean
        boolean_fields << field.id
        @form_results[field.id] = 0
      end
    end

    WebformFormResult.find_in_batches(:conditions => {:webform_form_id => self.id}) do |results|
      results.each do |result|
        options_fields.each do |field|
          if result.data[field].is_a?(Array)
            result.data[field].each { |value| @form_results[field][value] += 1 if @form_results[field][value] }
          else
            @form_results[field][result.data[field]] += 1 if @form_results[field][result.data[field]]
          end
        end

        boolean_fields.each do |field|
          @form_results[field] += 1 if result.data[field]
        end
      end
    end

    @form_results
  end

  def result_content_model_fields
    self.content_model_fields.collect do |field|
      if self.calculate_result_stats[field.id]
        [field, self.calculate_result_stats[field.id]]
      else
        nil
      end
    end.compact
  end

  def run_export_csv(args)
    tmp_path = "#{RAILS_ROOT}/tmp/export/"
    FileUtils.mkpath(tmp_path)
    
    filename = tmp_path + DomainModel.active_domain_id.to_s + "_webform_export.csv"

    self.export_csv(filename)

    domain_file = DomainFile.save_temporary_file filename, :name => sprintf("%s_%d.%s",'Webform_Results'.t,Time.now.strftime("%Y_%m_%d"),'csv')

    { :filename => filename,
      :domain_file_id => domain_file.id,
      :entries => self.webform_form_results.count,
      :type => 'text/csv',
      :completed => 1
    }
  end

  def export_csv(filename)
    logger.info "Exporing webform #{self.name}:#{self.id} to #{filename}"
    CSV.open(filename,'w') do |writer|
      WebformFormResult.find_in_batches(:conditions => {:webform_form_id => self.id}) do |results|
        results.each_with_index do |result,idx|
          result.export_csv(writer, :header => idx == 0)
        end
      end
    end
    logger.info "Finished exporing webform #{self.name}:#{self.id} to #{filename}"
  end
end
