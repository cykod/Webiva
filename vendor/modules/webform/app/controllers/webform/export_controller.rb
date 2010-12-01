
class Webform::ExportController < ModuleController # :nodoc: all
  permit 'webform_manage'

  component_info 'Webform'

  def generate_file
    form = WebformForm.find params[:path][0]
    session[:download_worker_key] = form.run_worker(:run_export_csv)
    render :nothing => true
  end
end
