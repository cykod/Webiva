# Copyright (C) 2010 Cykod LLC
class UserProfile::ManageController < ModuleController

  component_info 'UserProfile'     
  permit :user_profile_manage

  def self.members_view_handler_info 
    { :name => 'Profile', :controller => '/user_profile/manage', :action => 'view' } 
  end
 
  def user
    entry = UserProfileEntry.find(params[:path][0])
    redirect_to :controller => '/members', :action => 'view', :path => [ entry.end_user_id ] 
  end


  def view 
    @tab = params[:tab].to_i
    @user = EndUser.find(params[:path][0])
    @profile_type_id = params[:profile_type_id] if params[:profile_type_id]

    @profile_entry = UserProfileEntry.fetch_first_entry(@user,@profile_type_id) 

    if !@profile_entry
      return render :partial => 'no_profile_type'
    end

    if params[:profile]
      if @profile_entry.update_attributes params[:profile].slice(:published, :protected, :url)

        if @profile_entry.content_model && params[:entry]
          if @profile_entry.content_model.update_entry(@profile_entry.content_model_entry,params[:entry],@user)
            flash.now[:notice] = "Edited Profile"
          else
            @editing_profile = true
          end
        else
          flash.now[:notice] = "Edited Profile"
        end
      end
    end

    @matching_profile_types = UserProfileType.matching_types_options(@user.user_class_id)
    @current_profile_type_id = @profile_entry.user_profile_type_id

    render :partial => 'view'
  end
end
