class UserProfileUserHandler  < DomainModelExtension


  def after_save(usr)
    @profile_type_ids = UserProfileType.match_classes(usr.user_class_id)
    @profile_type_ids.each do |pt| 
      UserProfileEntry.fetch_entry(usr.id,pt).save
    end
  end
end
