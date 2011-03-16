
class ExperimentController < CmsController
  layout 'manage'

  cms_admin_paths 'marketing',
    'Marketing' => { :controller => '/emarketing', :action => 'index' },
    'Experiments' => { :action => 'index' }
  
  permit 'editor_visitors'

  include ActiveTable::Controller   
  active_table :experiments_table,
                Experiment,
                [ hdr(:icon, '', :width=>10),
                  :name,
                  hdr(:static, 'Status'),
                  hdr(:static, 'Test Page'),
                  hdr(:static, 'Conversion Page'),
                  hdr(:static, :note),
                  :started_at,
                  :ended_at,
                  :created_at
                ]

  def display_experiments_table(display=true)
    active_table_action('experiment') do |act,ids|
      experiments = Experiment.find(ids)
      case act
      when 'delete': experiments.each { |exp| exp.destroy unless exp.is_running? }
      end
    end

    @active_table_output = experiments_table_generate params, :order => 'experiments.created_at DESC'
    render :partial => 'experiments_table' if display
  end

  def index
    cms_page_path ['Marketing'], 'Experiments'
    display_experiments_table(false)
  end

  active_table :versions_table,
                ExperimentVersion,
                [ hdr(:icon, '', :width=>10),
                  hdr(:static, :revision),
                  hdr(:static, :language),
                  hdr(:static, 'Weight'),
                  hdr(:static, 'Visits'),
                  hdr(:static, 'Conversions'),
                  hdr(:static, 'Success')
                ]

  def display_versions_table(display=true)
    @experiment ||= Experiment.find params[:path][0]
    @active_table_output = versions_table_generate params, :order => 'id', :conditions => ['experiment_id = ?', @experiment.id]
    render :partial => 'versions_table' if display
  end

  def versions
    @experiment = Experiment.find params[:path][0]
    cms_page_path ['Marketing', 'Experiments'], @experiment.name
    display_versions_table(false)
  end
end
