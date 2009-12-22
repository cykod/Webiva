# Copyright (C) 2009 Pascal Rettig.

class Feedback::ManageRatingsController < ModuleController
  layout 'manage'

  component_info 'feedback'
  
  permit 'feedback_manage' 
  
  
   include ActiveTable::Controller   
   active_table :ratings_table,
                FeedbackEndUserRating,
                [ hdr(:icon, ''),
                  hdr(:options, 'target_type', :options => :get_target_types, :label => 'Type', :display => 'select',:noun => 'Type'),
                  hdr(:options, 'target_id', :options => :get_target_ids,  :label => 'Item', :display => 'select', :noun => 'Item' ),
                  hdr(:number, 'rating'),
                  hdr(:string, 'end_user_id', :label => 'Rated By'),
                  hdr(:string, 'rated_ip', :label => 'Rater IP',:width => '80'),
                  :rated_at
                ]
                
   active_table :user_ratings_table,
                FeedbackEndUserRating,
                [ hdr(:icon, ''),
                  hdr(:options, 'target_type', :options => :get_target_types, :label => 'Type', :display => 'select',:noun => 'Type'),
                  hdr(:options, 'target_id', :options => :get_user_target_ids,  :label => 'Item', :display => 'select', :noun => 'Item' ),
                  hdr(:number, 'rating'),
                  hdr(:string, 'rated_ip', :label => 'Rater IP',:width => '80'),
                  :rated_at
                ]
                
                
                
  protected

  def get_target_types
    FeedbackEndUserRating.find(:all,:select => 'DISTINCT(target_type) as target_type',:group => 'target_type',:order => 'target_type').collect do |type|
      [ type.target_type.constantize.get_content_description, type.target_type ]
    end
  end

  def get_target_ids
    if !session[:active_table][:ratings_table]['target_type'].blank?
      session[:active_table][:ratings_table]['target_type'].constantize.get_content_options
    else
      [['Select a Target type'.t,'']]
    end
  end

  def get_user_target_ids
    if !session[:active_table][:user_ratings_table]['target_type'].blank?
      session[:active_table][:user_ratings_table]['target_type'].constantize.get_content_options
    else
      [['Select a Target type'.t,'']]
    end
  end

  public
  
  def self.members_view_handler_info
    { 
      :name => 'Ratings',
      :controller => '/feedback/manage_ratings',
      :action => 'user_ratings'
    }
  end
  
  def user_ratings
    @user_id = params[:path][0]
    user_ratings_table(false)
    render :partial => 'user_ratings'
  end
  
  def user_ratings_table(display = true)
      @user_id = params[:path][0]
      ratings_helper
      @active_table_output = user_ratings_table_generate params, :per_page => 20, :include => :end_user, :order => 'rated_at DESC', :conditions => ['end_user_id = ?', params[:path][0]]
      render :partial => 'user_ratings_table' if display
  end
  
  

  def ratings_table(display = true)
      ratings_helper
      @active_table_output = ratings_table_generate params, :per_page => 20, :include => :end_user, :order => 'rated_at DESC'
      render :partial => 'ratings_table' if display
  end

  def index
      cms_page_info [ ['Content',url_for(:controller => '/content') ], 'Ratings' ], 'content'
      ratings_table(false)
  end
  
  protected
  
  def ratings_helper

      if request.post? && params[:table_action] && params[:rating].is_a?(Hash)
        rating_id_string = params[:rating].keys.collect { |cmt| DomainModel.connection.quote(cmt) }.join(",")
        case params[:table_action]
        when 'delete':
          FeedbackEndUserRating.destroy_all("id IN (#{rating_id_string})")
        end
        DataCache.expire_content('FeedbackEndUserRatings')
      end
  
  end
  

end
