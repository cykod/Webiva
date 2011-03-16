

class UserProfile::UserEditExtension < Handlers::ParagraphFormExtension

  def self.editor_auth_user_edit_feature_handler_info
    { 
      :name => 'User Profile Publication',
      :paragraph_options_partial => '/user_profile/page/auth_user_edit'
    }
  end


  # Paragraph Setup options
  def self.paragraph_options(val={ })
    opts = HashModel.new(val)
  end


  # Generates called with the paragraph parameters
  def generate(params,user)
    @user = user

    @entry = UserProfileEntry.fetch_first_entry(user) 
    @entry.attributes = (params[:user_profile]||{}).slice(:published,:protected) if @entry
  end

  # Called before the feature is displayed
  def feature_data(data)
    data[:user_profile] = @entry
  end

  # Adds any feature related tags
  def feature_tags(c,data)
    c.fields_for_tag('edit:user_profile','user_profile') { |t| data[:user_profile]}
    c.field_tag('edit:user_profile:published', :control => :check_box, :single => true)
    c.field_tag('edit:user_profile:protected', :control => :check_box, :single => true)
  end

  # Validate the submitted data
  def valid?
    true
  end

  # After everything has been validated 
  # Perform the actual form submission
  def post_process(user)
    @entry.save if @entry
  end

end
