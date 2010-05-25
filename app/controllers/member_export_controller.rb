# Copyright (C) 2009 Pascal Rettig.

class MemberExportController < CmsController # :nodoc: all
  layout 'manage'
  permit 'editor_members'

  cms_admin_paths "people",
                  "People" => { :controller => '/members' },
                  "User Lists" => { :controller => '/members', :action => 'segments' }

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

    worker_key = MemberExportWorker.async_do_work( :domain_id => DomainModel.active_domain_id,
                                      :export_options => (params[:export] || {})[:include],
                                      :user_segment_id => @segment ? @segment.id : nil
                                      )

    session[:member_download_worker_key] = worker_key
    
    render :nothing => true
  end
  
  def status
    if(session[:member_download_worker_key]) 
      results = Workling.return.get(session[:member_download_worker_key])
      
      @completed = results ? (results[:completed] || false) : false
    end
  end
  
  def download_file
    if(session[:member_download_worker_key]) 
      results = Workling.return.get(session[:member_download_worker_key])
      send_file(results[:filename],
          :stream => true,
	  :type => "text/" + results[:type],
	  :disposition => 'attachment',
	  :filename => sprintf("%s_%d.%s",'Email_Targets'.t,Time.now.strftime("%Y_%m_%d"),results[:type])
	  )
	  
	  
      session[:member_download_worker_key] = nil
    else
      render :nothing => true
    end
  
  end
end
