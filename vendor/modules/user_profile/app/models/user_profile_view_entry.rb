class UserProfileViewEntry < DomainModel 

  after_save :add_view_counts

  def add_view_counts
    @count = UserProfileViewCount.find_by_id(self.user_profile_entry_id) || UserProfileViewCount.create(:user_profile_entry_id => self.user_profile_entry_id, :total_views => 0)
    @count.total_views += 1
    @count.save
  end

end

