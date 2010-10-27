# Copyright (C) 2010 Cykod LLC

class UserProfile::PageController < ParagraphController

  editor_header 'User Profile Paragraphs'

  editor_for :display_profile, :name => "Display Profile", :feature => :user_profile_page_display_profile, :inputs => { :user_profile => [ [:url, 'User URL', :path]] }, :outputs => [ [ :profile_content, "Profile Entry",:target], [ :profile_myself, "Viewing Own Profile", :target], [ :user, 'User Target',:target ], [:user_content, 'User Content', :content ]]

  editor_for :list_profiles, :name => 'List Profiles', :feature => :user_profile_page_list_profiles


  class DisplayProfileOptions < HashModel
    # this needs to be set as a paragraph option.. they have to pick which profile they want displayed on the page
    attributes  :profile_type_id => nil, :default_to_user => true
    boolean_options :default_to_user

    validates_presence_of :profile_type_id

    canonical_paragraph "UserProfileType", :profile_type_id

    options_form(fld(:profile_type_id,:select,:options => :profile_type_select_options),
                 fld(:default_to_user,:yes_no))

    def profile_type_select_options
      UserProfileType.select_options_with_nil
    end
  end


  class ListProfilesOptions < HashModel
    attributes :profile_type_id => nil, :order_by => 'newest', :registered_only => true, :per_page => 20, :hide_protected => false, :profile_detail_page_id => nil

    validates_presence_of :profile_type_id
    integer_options :per_page
    page_options :profile_detail_page_id
    boolean_options :registered_only, :hide_protected


    has_options :order_by, [['Newest','newest'],['Updated','updated'],['Alphabetical','alpha']]

    options_form(fld(:profile_type_id,:select,:options => :profile_type_select_options),
                 fld(:profile_detail_page_id, :page_selector, :description => 'Leave blank for cannonical url'),
                 fld(:order_by,:select, :options => :order_by_select_options),
                 fld(:per_page,:text_field),
                 fld(:hide_protected,:yes_no,:description => 'Hide protected users'),
                 fld(:registered_only,:yes_no,:description => 'Only show registered users (recommended)'))

    def profile_type_select_options
      UserProfileType.select_options_with_nil
    end

  end


end
