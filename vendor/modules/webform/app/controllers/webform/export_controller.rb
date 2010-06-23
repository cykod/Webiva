
class Webform::ExportController < ModuleController # :nodoc: all
  permit 'webform_manage'

  component_info 'Webform'

  cms_admin_paths 'content', 
                  'Content' => { :controller => '/content' },
                  'Webforms' => { :action => 'index' }

  def generate_file
    form = WebformForm.find params[:path][0]
    session[:webform_download_worker_key] = form.run_worker(:run_export_csv)
    render :nothing => true
  end
  
  def status
    if(session[:webform_download_worker_key]) 
      results = Workling.return.get(session[:webform_download_worker_key])
      logger.error results.inspect
      @completed = results ? (results[:completed] || false) : false
    end
  end
  
  def download_file
    if(session[:webform_download_worker_key]) 
      results = Workling.return.get(session[:webform_download_worker_key])
      send_domain_file(results[:domain_file_id], :type => "text/" + results[:type])
      session[:webform_download_worker_key] = nil
    else
      render :nothing => true
    end
  end
end
