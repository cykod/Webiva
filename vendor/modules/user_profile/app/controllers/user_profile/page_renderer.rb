
# Copyright (C) 2010 Cykod LLC
#
#
class UserProfile::PageRenderer < ParagraphRenderer

  features '/user_profile/page_feature'

  paragraph :display_profile
  paragraph :list_profiles

  def display_profile
    @options = paragraph_options(:display_profile)

    @user_profile = find_profile

    is_myself = @user_profile && @user_profile.end_user == myself

    display_string = is_myself ? 'myself' : 'other' 

    result = renderer_cache(@user_profile,display_string, :skip => true) do |cache|
      if @user_profile
        @profile_user = @user_profile.end_user
        @content_model = @user_profile.content_model
        @user_profile_type  = @user_profile.user_profile_type
        cache[:full_name] = @profile_user.full_name if @profile_user
      end

      @url = site_node.node_path

      cache[:output] =  user_profile_page_display_profile_feature
    end

    if @user_profile
      set_title(result.full_name)
      set_title(result.full_name,"profile")
      set_page_connection(:profile_content, @user_profile)
      set_page_connection(:profile_myself, is_myself ? @user_profile : nil)
      set_page_connection(:user_target, @user_profile.end_user )
      set_page_connection(:user_content, [ "EndUser", @user_profile.end_user_id ])
      set_content_node(@user_profile)
    end

    render_paragraph :text => result.output
  end

  @@profile_order_by_options = { 'newest' => 'end_users.created_at DESC',
                                 'updated' => 'end_users.updated_at DESC',
                                 'alpha' => 'end_users.last_name, end_users.first_name' }

  def list_profiles
    @options = paragraph_options(:list_profiles)

    result = renderer_cache(UserProfileEntry) do |cache|
      @user_profile_type = UserProfileType.find_by_id(@options.profile_type_id)   

      return render_paragraph :text => 'Configure Paragraph'.t if !@user_profile_type

      order_by = @@profile_order_by_options[@options.order_by]
      @pages,@users = @user_profile_type.paginate_users(params[:page],:order => order_by, :registered => @options.registered_only)
      @content_model = @user_profile_type.content_model

      cache[:output] = user_profile_page_list_profiles_feature
    end

    render_paragraph :text => result.output
  end
  
  def find_profile
    if editor?
      UserProfileEntry.find(:first,:conditions => { :user_profile_type_id => @options.profile_type_id})
    else
      conn_type,url = page_connection(:user_profile)
      if url.blank? && @options.default_to_user
        UserProfileEntry.find_by_end_user_id_and_user_profile_type_id(myself.id, @options.profile_type_id) ||
          UserProfileEntry.fetch_first_entry(myself,@options.profile_type_id)
      else
        profile = UserProfileEntry.find_by_url_and_user_profile_type_id(url, @options.profile_type_id)
        profile && profile.published? ? profile : nil
      end
    end


  end

end
