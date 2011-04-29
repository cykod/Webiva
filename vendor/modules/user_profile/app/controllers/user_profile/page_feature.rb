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
      c.expansion_tag('user:published') { |t| data[:user_profile].published? }
      c.expansion_tag('user:protected') { |t| data[:user_profile].protected? } 
      c.loop_tag('user:tag') { |t| t.locals.user.tags_array }
      c.h_tag('user:tag:tag_name') { |t| t.locals.tag }
      c.expansion_tag('user:tagged') { |t| t.locals.user.tags_array.include?(t.attr['tag'].to_s.titleize) }
      c.loop_tag('user:access_token') { |t| t.locals.user.access_tokens }
      c.h_tag('user:access_token:token') { |t| t.locals.access_token.name }
      c.expansion_tag('user:has_token') { |t| t.locals.user.access_tokens.detect { |token| token.name == t.attr['token'].to_s } }
      c.content_model_fields_value_tags('user:profile', data[:user_profile_type].display_content_model_fields) if data[:content_model]
    end 
  end


  feature :user_profile_page_list_profiles, :default_feature => <<-FEATURE
  <cms:users>
   <ul class='users'>
   <cms:user>
     <li>
     <cms:img align='left'/>
     <h2><cms:link><cms:name/></cms:link></h2>
     </li>
   </cms:user>
   </ul>
   <cms:pages/>
  </cms:users>

FEATURE


def user_profile_page_list_profiles_feature(data)
  webiva_custom_feature(:user_profile_page_list_profiles,data) do |c|
    c.loop_tag('user') { |t| data[:users] }
    c.user_details_tags('user') { |t| t.locals.user.end_user }
    c.link_tag('user:') do |t| 
      if data[:options].profile_detail_page_url
       "#{data[:options].profile_detail_page_url}/#{t.locals.user.url}"
      else
       data[:user_profile_type].content_type.content_link(t.locals.user) 
      end
    end
    c.expansion_tag('user:profile') { |t| t.locals.entry = t.locals.user.content_model_entry if data[:content_model] }

    c.content_model_fields_value_tags('user:profile',data[:user_profile_type].display_content_model_fields) if data[:content_model]
    c.pagelist_tag('pages') { |t| data[:pages] }
  end
end


end
