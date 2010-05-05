
# Copyright (C) 2010 Cykod LLC
#
#
class UserProfile::PageRenderer < ParagraphRenderer

  features '/user_profile/page_feature'

  paragraph :display_profile
  def display_profile
    @options = paragraph_options(:display_profile)
    @user_profile = find_profile
    if @user_profile
      @profile_user = @user_profile.end_user
      @content_model = @user_profile.content_model
      @user_profile_type  = @user_profile.user_profile_type
      set_title(@profile_user.full_name)
      set_title(@profile_user.full_name,"profile")
      set_page_connection(:profile_content, ['UserProfileEntry',@user_profile.id])
      set_content_node(@user_profile)
    end

    @url = site_node.node_path

    render_paragraph :feature => :user_profile_page_display_profile
  end
  
  def find_profile
    if editor?
      UserProfileEntry.find(:first,:conditions => { :user_profile_type_id => @options.profile_type_id})
    else
      conn_type,url = page_connection(:user_profile)
      if url.blank? && @options.default_to_user
        UserProfileEntry.find_by_end_user_id_and_user_profile_type_id(myself.id, @options.profile_type_id)
      else
        UserProfileEntry.find_by_url_and_user_profile_type_id(url, @options.profile_type_id)
      end
    end


  end

end
