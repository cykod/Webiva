# Copyright (C) 2009 Pascal Rettig.

class MemberExportController < CmsController # :nodoc: all
  layout 'manage'
  permit 'editor_members'

  cms_admin_paths "people",
                  "People" => { :controller => '/members' }

  def index    
    @export = DefaultsHashObject.new(:download => 'all')
    
    @include_options = [ [ 'Home Address','home' ], 
                         ['Billing Address', 'billing'], 
                         ['Work Address','work'],
                         ['VIP Number', 'vip' ],
                         ['Tags','tags']
                       ]

    @segment = UserSegment.find_by_id params[:path][0]

    cms_page_path ["People", [@segment ? @segment.name : 'Everyone'.t, url_for(:controller => 'members', :action => 'index', :path => @segment ? @segment.id : nil)]], 'Export Users'

    @member_count = @segment ? @segment.last_count : EndUser.count(:conditions => {:client_user_id => nil})
  end
  
  def generate_file
    @segment = UserSegment.find_by_id params[:path][0]

    session[:download_worker_key] = MemberExportWorker.async_do_work(
                                      :domain_id => DomainModel.active_domain_id,
                                      :export_options => (params[:export] || {})[:include],
                                      :user_segment_id => @segment ? @segment.id : nil
                                    )

    render :nothing => true
  end
end
