# Copyright (C) 2009 Pascal Rettig.

class ContentExportController < CmsController # :nodoc: all
  layout 'manage'
  permit 'editor_content'
  
  def index
    content_id = params[:path][0]
    
    @content_model = ContentModel.find(content_id) 
    
    @entry_count = @content_model.content_model.count
    
    @export = DefaultsHashObject.new(:download => 'all', :export_format => 'csv')
    
    cms_page_info([ [ 'Content', url_for(:action => 'index') ] , 
                    [ 'View Content', url_for(:controller => '/content', :action => 'view', :path => content_id) ],
                    'Download Data' ])
                    
                    
    @export_options =  [[ 'CSV - Comma Separated Values, Easy import into Microsoft Excel', 'csv' ],
                       [ 'XML - a Common Data Interchange format', 'xml' ],
                       [ 'YAML - Scripting language interchange format',  'yaml'] ]
                       
       
  end
  
  def generate_file
    content_id = params[:path][0]
    
    @content_model = ContentModel.find(content_id) 
    
    session[:download_worker_key] = ContentExportWorker.async_do_work( :domain_id => DomainModel.active_domain_id,
                                                 :content_model_id => content_id, 
                                                 :export_download => params[:export][:download],
                                                 :export_format => params[:export][:export_format], 
                                                 :range_start => params[:export][:range_start],
                                                 :range_end => params[:export][:range_end] 
                                                )
    render :nothing => true
  end  
end
