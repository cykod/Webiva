# Copyright (C) 2009 Pascal Rettig.

class Feedback::AdminController < ModuleController

  component_info 'Feedback', :description => 'Support user feedback (Comments & Ratings) on your website', 
                              :access => :public
                              
  content_model :feedback
  
  register_handler :members, :view, "Feedback::FeedbackController"
  
  register_permission_category :feedback, "Feedback" ,"Feedback & Comments Permissions"
  register_permissions :feedback, [  [ :manage, 'Manage Feedback','Manage Feedback'   ]]



  protected
  def self.get_feedback_info
      [
      {:name => "Feedback",:url => { :controller => '/feedback/feedback' } ,:permission => 'feedback_manage', :icon => 'icons/content/feedback.gif' }
      ]
  end

end
