
class Feedback::ManagePingbacksController < ModuleController
  layout 'manage'

  component_info 'feedback'
  
  permit 'feedback_manage' 
  
  include ActiveTable::Controller   
  active_table :pingbacks_table, FeedbackPingback,
    [ hdr(:icon, ''),
    :has_comment,
    :source_uri,
    :target_uri,
    :title,
    hdr(:static, 'excerpt'),
    :posted_at
  ]
  
  def pingbacks_table(display = true)
    pingbacks_helper
    @active_table_output = pingbacks_table_generate params, :per_page => 20, :order => 'posted_at DESC'
    render :partial => 'pingbacks_table' if display
  end

  def index
    cms_page_info [ ['Content',url_for(:controller => '/content') ], 'Pingback' ], 'content'
    pingbacks_table(false)
  end
  
  protected
  
  def pingbacks_helper
    if request.post? && params[:table_action] && params[:pingback].is_a?(Hash)
      pingback_id_string = params[:pingback].keys.collect { |cmt| DomainModel.connection.quote(cmt) }.join(",")
      case params[:table_action]
      when 'delete':
          FeedbackPingback.destroy_all("id IN (#{pingback_id_string})")
      when 'create':
          FeedbackPingback.create_comments(myself, params[:pingback].keys)
      when 'remove':
          Comment.destroy_all("source_type = 'FeedbackPingback' and source_id IN (#{pingback_id_string})")
	  FeedbackPingback.update_all('has_comment=0', "id IN (#{pingback_id_string})")
      end
      DataCache.expire_content('FeedbackEndUserPingback')
    end
  end
end
