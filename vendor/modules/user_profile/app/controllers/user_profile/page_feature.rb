# Copyright (C) 2010 Cykod LLC


class UserProfile::PageFeature < ParagraphFeature

  feature :user_profile_page_display_profile, :default_feature => <<-FEATURE
<cms:user>
  <cms:name/>
  <br/><cms:img /> 

<cms:profile>
 <!-- Custom Fields here -->
</cms:profile>

</cms:user>

<cms:no_user>
Please re-enter the URL, no profile exists for the name entered
</cms:no_user>
  FEATURE

  def user_profile_page_display_profile_feature(data)
    webiva_custom_feature(:user_profile_page_display_profile,data) do |c|
      c.expansion_tag('user') { |t| t.locals.user = data[:profile_user] }
      c.user_details_tags('user') { |t| t.locals.user }
      c.expansion_tag('user:profile') { |t| t.locals.entry = data[:user_profile].content_model_entry if data[:content_model] }
      c.expansion_tag('logged_in') { |t| myself.id }
      c.content_model_fields_value_tags('user:profile', data[:user_profile_type].display_content_model_fields) if data[:content_model]
    end 
  end

  feature :user_profile_page_profile_privacy, :default_feature => <<-FEATURE
<cms:user>
  <cms:name/>
  <br/><cms:img /> 

<cms:profile_options>
<cms:protected/>
<cms:private/>
</cms:profile_options>

</cms:user>

<cms:no_user>
Please re-enter the URL, no profile exists for the name entered
</cms:no_user>
  FEATURE


  def user_profile_page_profile_privacy_feature(data)
    webiva_feature(:user_profile_page_profile_privacy,data) do |c|
      c.user_details_tags('user') { |t| t.locals.user }
      c.expansion_tag("myself") { |t| t.locals.user == myself }

      c.form_for_tag('profile_options','profile_options') { |t|  data[:profile_entry_options] }
      c.field_tag('profile_options:protected', :control => :check_box)
      c.field_tag('profile_options:private', :control => :check_box)
    end 
  end
end


