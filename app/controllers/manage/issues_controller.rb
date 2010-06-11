# Copyright (C) 2009 Pascal Rettig.

class Manage::IssuesController < CmsController # :nodoc: all

  permit 'system_admin'
  layout 'manage'

  private
  
  def build_tree(issues)
    tree =  {}
    
    branch_id =0 
    
    issues.each do |issue|
      
      tree[issue.reporting_domain] ||= { :issue_cnt => 0, :branches => {} }
      
      tree[issue.reporting_domain][:issue_cnt] += 1
      
      if issue.location =~ /^([^:]+)\:\/?(.*?)\/?$/
        branch_name = $1
        tree[issue.reporting_domain][:branches][branch_name] ||= { :issue_cnt => 0, :issues => [], :branches => {} }
        
        loc = $2
        loc = loc.split("/")
        
        cur_branch = tree[issue.reporting_domain][:branches][branch_name]
        
        loc.each do |new_branch|
          if !new_branch.empty?
            cur_branch[:issue_cnt] += 1
            cur_branch[:branches][new_branch] ||= { :issue_cnt => 0, :issues => [], :branches => {} }
            cur_branch = cur_branch[:branches][new_branch]
          end
        end
        
        cur_branch[:issue_cnt] += 1
        cur_branch[:issues] << issue
        
      else
        tree[issue.reporting_domain][:branches]['invalid'] ||= { :issue_cnt => 0, :issues => [] }
        tree[issue.reporting_domain][:branches]['invalid'][:issues] << issue
        tree[issue.reporting_domain][:branches]['invalid'][:issue_cnt] += 1
      end
      
    
    end
    
    tree
  end

  public
  
  def index
  
    session[:issues_show_all] = params[:show_all] || session[:issues_show_all]
    @show_all = session[:issues_show_all].to_i == 1 ? true : false
    
    cms_page_info([ ['System',url_for(:controller => '/manage/system') ], 'Issues'])
  
    
    if @show_all 
      issues = SystemIssue.find(:all, :order => 'location, reported_at')
    else
      issues = SystemIssue.find(:all,:conditions => 'status NOT IN ("closed","complete")', :order => 'location, reported_at')
    end
    
    @issue_tree = build_tree(issues)
    
    @branch_idx = 0
  end
  
  
  def new
    cms_page_info([ ['System',url_for(:controller => '/manage/system') ], [ 'Issues', url_for(:controller => '/manage/issues') ], 'New Issue' ])
    
    @issue = SystemIssue.new(:reported_at => Time.now,
                             :reporter_user => myself,
                             :status => 'reported',
                             :reported_type => 'manual',
                             :reporting_domain => DomainModel.active_domain_name
                             )
  
    if request.post?
      if @issue.update_attributes(params[:issue])
        redirect_to :action => 'index'
      end
    
    end
  
  end
  
  def issue
    @issue = SystemIssue.find(params[:path][0])
    
    @issue_note = @issue.system_issue_notes.new
    
    render :partial => 'issue_details', :locals => {:issue => @issue } 
  
  end
  
  def quick_close
  
    issues = params[:iid]
    
    issues.each do |issue|
      @issue = SystemIssue.find(issue)
      @issue.update_attribute(:status,'closed')
      @issue_note = @issue.system_issue_notes.create(:entered_at => Time.now,
						    :entered_user => myself,
						    :action => 'closed'
						    )
    end
    
    render :nothing => true
  end
  
  def add_note
    @issue = SystemIssue.find(params[:path][0])
    
    @issue_note = @issue.system_issue_notes.build(:entered_at => Time.now,
                                                  :entered_user => myself
                                                  )
    
    @issue_note.attributes = params[:note]
    if @issue_note.valid?
       update_issue = false
      if @issue_note.action == 'closed' || @issue_note.action == 'complete'
        @issue.status = @issue_note.action
        update_issue =true
      elsif @issue.status == 'reported'
        @issue.status = 'commented'
        updated_issue = true
      end
      
      if @issue_note.work_time > 0
        @issue.time_log += @issue_note.work_time
      end
    
      @issue.save if update_issue
      @issue_note.save
      
      @issue_note = @issue.system_issue_notes.new
    else
      @issue.system_issue_notes.reload
    end
    
    render :partial => 'issue_details', :locals => {:issue => @issue } 
  end
  
  def update_issue
    @issue = SystemIssue.find(params[:path][0])
    
    @issue.update_attributes(params[:issue])
    
    redirect_to :action => 'index'
    
  end

  protected

  include Manage::SystemController::Base
end
