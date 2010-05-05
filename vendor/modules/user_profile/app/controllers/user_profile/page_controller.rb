# Copyright (C) 2010 Cykod LLC

class UserProfile::PageController < ParagraphController

  editor_header 'User Profile Paragraphs'

  editor_for :display_profile, :name => "Display Profile", :feature => :user_profile_page_display_profile, :inputs => { :user_profile => [ [:url, 'User URL', :path]] }, :outputs => [ [ :profile_content, "Profile Entry",:content] ]


  class DisplayProfileOptions < HashModel
    # this needs to be set as a paragraph option.. they have to pick which profile they want displayed on the page
    attributes  :profile_type_id => nil, :default_to_user => true
    page_options :profile_type_id
    boolean_options :default_to_user

    validates_presence_of :profile_type_id

    options_form(fld(:profile_type_id,:select,:options => :profile_type_select_options),
                 fld(:default_to_user,:radio_buttons,:options => :yes_no))

    def profile_type_select_options
      UserProfileType.select_options_with_nil
    end
    def yes_no
      [["Yes".t,true],["No".t,false]]
    end
  end


end
