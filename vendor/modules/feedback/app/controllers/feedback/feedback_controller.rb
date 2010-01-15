# Copyright (C) 2009 Pascal Rettig.

class Feedback::FeedbackController < ModuleController
  layout 'manage'

  component_info 'feedback'
  
  permit 'feedback_manage' 
  
  
   include ActiveTable::Controller   
   active_table :comments_table,
                Comment,
                [ hdr(:icon, ''),
                  hdr(:options, 'target_type', :options => :get_target_types, :label => 'Type', :display => 'select',:noun => 'Type'),
                  hdr(:options, 'target_id', :options => :get_target_ids,  :label => 'Item', :display => 'select', :noun => 'Item' ),
                  hdr(:options, 'rating', :options => [ ['Unrated',0],['Negative',-1],['Positive',1]], :icon => 'icons/table_actions/rating_none.gif', :width => '32'),
                  hdr(:string, 'end_user_id', :label => 'Posted By'),
                  hdr(:string, 'posted_ip', :label => 'Poster IP',:width => '80'),
                  :posted_at,
                  hdr(:string, 'comment') 
                ]
                
   active_table :user_comments_table,
                Comment,
                [ hdr(:icon, ''),
                  hdr(:options, 'target_type', :options => :get_target_types, :label => 'Type', :display => 'select',:noun => 'Type'),
                  hdr(:options, 'target_id', :options => :get_user_target_ids,  :label => 'Item', :display => 'select', :noun => 'Item' ),
                  hdr(:options, 'rating', :options => [ ['Unrated',0],['Negative',-1],['Positive',1]], :icon => 'icons/table_actions/rating_none.gif', :width => '32'),
                  hdr(:string, 'posted_ip', :label => 'Poster IP',:width => '80'),
                  :posted_at,
                  hdr(:string, 'comment') 
                ]
                
                
                
  protected

  def get_target_types
    Comment.find(:all,:select => 'DISTINCT(target_type) as target_type',:group => 'target_type',:order => 'name').collect do |type|
      target_type = type.target_type.constantize
      [ target_type.respond_to?(:get_content_description) ? target_type.get_content_description : target_type.to_s.titleize, type.target_type ]
    end
  end

  def get_target_ids
    if !session[:active_table][:comments_table]['target_type'].blank?
      session[:active_table][:comments_table]['target_type'].constantize.get_content_options
    else
      [['Select a Target type'.t,'']]
    end
  end

  def get_user_target_ids
    if !session[:active_table][:user_comments_table]['target_type'].blank?
      session[:active_table][:user_comments_table]['target_type'].constantize.get_content_options
    else
      [['Select a Target type'.t,'']]
    end
  end

  public
  
  def self.members_view_handler_info
    { 
      :name => 'Feedback',
      :controller => '/feedback/feedback',
      :action => 'user_comments'
    }
  end
  
  def user_comments
    @user_id = params[:path][0]
    user_comments_table(false)
    render :partial => 'user_comments'
  end
  
  def user_comments_table(display = true)
      @user_id = params[:path][0]
      comments_helper
      @active_table_output = user_comments_table_generate params, :per_page => 20, :include => :end_user, :order => 'posted_at DESC', :conditions => ['end_user_id = ?', params[:path][0]]
      render :partial => 'user_comments_table' if display
  end
  
  

  def comments_table(display = true)
      comments_helper
      @active_table_output = comments_table_generate params, :per_page => 20, :include => :end_user, :order => 'posted_at DESC'
      render :partial => 'comments_table' if display
  end

  def index
      cms_page_info [ ['Content',url_for(:controller => '/content') ], 'Feedback' ], 'content'
      comments_table(false)
  end
  
  protected
  
  def comments_helper

      if request.post? && params[:table_action] && params[:comment].is_a?(Hash)
        comment_id_string = params[:comment].keys.collect { |cmt| DomainModel.connection.quote(cmt) }.join(",")
        case params[:table_action]
        when 'approve':
          Comment.update_all("rating=1","id IN (#{comment_id_string})")
        when 'reject':
          Comment.update_all("rating=-1","id IN (#{comment_id_string})")
        when 'delete':
          Comment.destroy_all("id IN (#{comment_id_string})")
        end
        DataCache.expire_content('Comments')
      end
  
  end
  

end
