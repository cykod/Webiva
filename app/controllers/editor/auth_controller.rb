# Copyright (C) 2009 Pascal Rettig.

class Editor::AuthController < ParagraphController #:nodoc:all
  permit 'editor_editor'
  
  user_actions [:add_feature, :add_login_feature, :add_user_edit_feature]

  # Editor for authorization paragraphs
  editor_header "Member Paragraphs", :paragraph_member
  editor_for :login, :name => 'User Login', :features => ['login']
  editor_for :enter_vip, :name => 'Enter VIP #', :features => ['enter_vip'], :triggers => [['Failed VIP Login','failure'],['Successful VIP Login','success' ],['Repeat Successful VIP Login','repeat']]

  editor_for :user_register, :name => 'User Registration', :feature => 'user_register', :triggers => [ ['Successful Registration','action'] ], :inputs => { :source => [[:source, 'Source',:path]], :tag => [[:add_tag,'Tag',:path ]] }

  editor_for :user_activation, :name => 'User Activation', :feature => 'user_activation', :triggers => [ ['Successful Activation','action'] ]

  editor_for :user_edit_account, :name => 'User Edit Account', :feature => 'user_edit_account', :triggers => [ ['Edit Account','action' ]] 

  editor_for :missing_password, :name => 'Missing Password', :triggers => [ ['Sent Email','action']], :features => ['missing_password']
  
  editor_for :email_list, :name => 'Email List Signup', :triggers => [ ['Signed Up','action']], :features => ['email_list'], :inputs => [ [:source,"Source URL",:path ]] 
  editor_for :splash, :name => 'Splash Page'
  editor_for :view_account, :name => 'View Account', :no_options => true
  
  class UserRegisterOptions < HashModel
    
    # For feature stuff
    include HandlerActions

    
    attributes :registration_type => 'account',
    :required_fields => [ ], :optional_fields => [ 'first_name','last_name'],
    :success_page_id => nil, :already_registered_page_id => nil,
    :user_class_id => nil,  :modify_profile => 'modify', :registration_template_id => nil,
    :include_subscriptions => [], :country => 'United States', :add_tags => '',
    :work_address_required_fields => [],
    :address_required_fields => [],
    :content_publication_id => nil, :source => nil, :lockout_redirect => false,
    :require_activation => false, :activation_page_id => nil,
    :features => [], :require_captcha => false, :user_level => 4

    boolean_options :lockout_redirect, :require_activation, :require_captcha

    page_options :success_page_id, :activation_page_id 
   
    validates_presence_of :success_page_id, :user_class_id

    integer_options :user_level
    integer_array_options :include_subscriptions

    def validate
      self.required_fields = [] if @passed_hash[:required_fields].blank?
      self.optional_fields = [] if @passed_hash[:optional_fields].blank?
       if !self.features.is_a?(Array)
        self.features = self.features.to_a.sort {  |a,b| a[0] <=> b[0]  }.map {  |elm| obj = Handlers::ParagraphFeature.new(elm[1]);  obj.to_hash }

        self.register_features.each do |feature|
          if !feature.options.valid?
            self.errors.add_to_base('Feature Error')
          end
        end
       
      end
    end

    def available_field_list
      { :email => [ 'Email'.t,:text_field, :email ],
        :password => [ 'Password'.t, :password_field, :password ],
        :password_confirmation => [ 'Confirm Password'.t, :password_field, :password_confirmation ],
        :first_name => ['First Name'.t,:text_field,:first_name],
        :middle_name => ['Middle Name'.t,:text_field,:middle_name],
        :dob => [ 'Date of Birth'.t,:text_field,:dob],
        :last_name => ['Last Name'.t,:text_field,:last_name],
        :gender => ['Gender'.t, :radio_buttons, :gender, { :options => [ ['Male'.t,'m'],['Female'.t,'f' ] ] } ],
        :introduction => ['Introduction'.t, :radio_buttons, :introduction, { :options => [ ['Mr.'.t,'Mr.'],['Mrs.'.t,'Mrs.' ], ['Ms.'.t, 'Ms.'] ] } ],
        :username => [ 'Username'.t,:text_field, :username ],
        :salutation => [ 'Salutation'.t,:text_field, :salutation ],
        :image => [ 'Profile Image'.t,:upload_image, :domain_file_id ],
        :referral => ['Referral'.t, :text_field, :referral]
      }
    end

    def available_optional_field_options
      opts = available_field_list
      opts.delete(:email)
      opts.delete(:password)
      opts.delete(:password_confirmation)
      opts.map { |elm| [ elm[1][0],elm[0].to_s ] }.sort
    end

    def available_field_options
      available_field_list.to_a.map { |elm| [ elm[1][0],elm[0].to_s ] }.sort
    end

    def all_field_list
       available_field_list.to_a
    end

    def any_field_list
      flds = available_field_list
      fields = (self.required_fields + self.optional_fields).uniq
      ['password_confirmation','password','email'].each do |fld|
        fields.unshift(fld) if !fields.include?(fld)
      end
      fields.map { |elm| flds[elm.to_sym] ? [ elm.to_sym, flds[elm.to_sym] ] : nil }.compact
    end

    def always_required_fields
      flds = [ 'email']
      flds += [ 'password','password_confirmation'] if self.registration_type == 'account'
      flds
    end

    def required_field_list
      flds = available_field_list
      fields = (self.required_fields).uniq
      ['password_confirmation','password','email'].each do |fld|
        fields.unshift(fld) if !fields.include?(fld)
      end
      fields.map { |elm| flds[elm.to_sym] ? [ elm.to_sym, flds[elm.to_sym] ] : nil }.compact
    end

    def optional_field_list
      flds = available_field_list
      fields = (self.optional_fields).uniq
      fields.map { |elm| flds[elm.to_sym] ? [ elm.to_sym, flds[elm.to_sym] ] : nil }.compact
    end

    def available_address_field_list
      {
        :company => [ 'Company'.t, :text_field,:company],
        :phone => [ 'Phone'.t, :text_field,:phone],
        :fax => [ 'Fax'.t, :text_field,:fax],
        :address => [ 'Address'.t, :text_field,:address],
        :address_2 => [ 'Address (Line 2)'.t, :text_field,:address_2],
        :city => [ 'City'.t, :text_field,:city],
        :state => (self.country == 'United States' ? [ 'State'.t, :select,:state,{ :options => ContentModel.state_select_options } ] :
                                                [ 'State'.t, :text_field,:state] ),
        :zip => [ 'Zip Code'.t, :text_field,:zip],
	:country => [ 'Country'.t, :country_select, :country]
      }
    end

    def available_address_field_options(business = false)
      flds = available_address_field_list
      if(!business)
        flds.delete(:company)
       end
      flds.to_a.map { |elm| [ elm[1][0],elm[0].to_s ] }.sort
    end

    def address_field_list
      hsh = available_address_field_list
      hsh.delete(:company)
      hsh.to_a
    end

    def business_address_field_list
      available_address_field_list.to_a
    end

    def content_model
      if publication
        @content_mode ||= @pub.conten_model
      else
        nil
      end
    end

    def publication
      @pub ||= ContentPublication.find_by_id(self.content_publication_id)
    end
    
    def available_features
      [['--Select a feature to add--','']] + get_handler_options(:editor,:auth_user_register_feature)
     end

    def register_features
      @register_features ||= self.features.map do |feature|
        Handlers::ParagraphFeature.new(feature.merge({ :feature_type => 'editor_auth_user_register_feature'}))
      end
    end

    def subscriptions
      @subscriptions ||= self.include_subscriptions.collect do |subscription_id|
        UserSubscription.find_by_id subscription_id
      end.compact
    end

    def self.user_level_options
      EndUser.user_level_select_options.select { |lvl| lvl[1] >= 4 && lvl[1] <= 5 }
    end
  end

  class UserActivationOptions < HashModel
    attributes :require_acceptance => false, :redirect_page_id => nil, 
      :already_activated_redirect_page_id => nil, :login_after_activation => false

    page_options :redirect_page_id, :already_activated_redirect_page_id
    boolean_options :require_acceptance, :login_after_activation
  end

  class UserEditAccountOptions < HashModel
    
    # For feature stuff
    include HandlerActions

    
    attributes :required_fields => [ 'email' ],
    :user_class_id => nil,  :modify_profile => 'keep', :mail_template_id => nil,
    :optional_fields => [ 'first_name','last_name'],
    :success_page_id => nil,
    :include_subscriptions => [], :country => 'United States', :add_tags => '',
    :work_address_required_fields => [],
    :address_required_fields => [],
    :content_publication_id => nil, :content_publication_user_field => nil,
    :access_token_id => nil, :user_level => 4,
    :features => []

    page_options :success_page_id

    integer_options :user_level

    integer_array_options :include_subscriptions

    validates_presence_of :user_class_id

    def validate
      self.required_fields = [] if @passed_hash[:required_fields].blank?
      self.optional_fields = [] if @passed_hash[:optional_fields].blank?
      if self.content_publication_id
        if self.content_publication_user_field
          errors.add(:content_publication_user_field) unless self.publication_field_options.rassoc self.content_publication_user_field
        else
          errors.add(:content_publication_user_field) unless self.content_publication_user_field
        end
      end
      if !self.features.is_a?(Array)
        self.features = self.features.to_a.sort {  |a,b| a[0] <=> b[0]  }.map {  |elm| obj = Handlers::ParagraphFeature.new(elm[1]);  obj.to_hash }

        self.user_edit_features.each do |feature|
          if !feature.options.valid?
            self.errors.add_to_base('Feature Error')
          end
        end
      end
    end

    def user_edit_features
      @edut_features ||= self.features.map do |feature|
        Handlers::ParagraphFeature.new(feature.merge({ :feature_type => 'editor_auth_user_edit_feature'}))
      end
    end

    def available_features
      [['--Select a feature to add--','']] + get_handler_options(:editor,:auth_user_edit_feature)
     end

    def available_field_list
      { :email => [ 'Email'.t,:text_field, :email ],
        :password => [ 'Reset Password'.t, :password_field, :password ],
        :password_confirmation => [ 'Confirm Password'.t, :password_field, :password_confirmation ],
        :first_name => ['First Name'.t,:text_field,:first_name],
        :middle_name => ['Middle Name'.t,:text_field,:middle_name],
        :last_name => ['Last Name'.t,:text_field,:last_name],
        :gender => ['Gender'.t, :radio_buttons, :gender, { :options => [ ['Male'.t,'m'],['Female'.t,'f' ] ] } ],
        :introduction => ['Introduction'.t, :radio_buttons, :introduction, { :options => [ ['Mr.'.t,'Mr.'],['Mrs.'.t,'Mrs.' ], ['Ms.'.t, 'Ms.'] ] } ],
        :username => [ 'Username'.t,:text_field, :username ],
        :salutation => [ 'Salutation'.t,:text_field, :salutation ],
        :image => [ 'Upload Profile Image'.t,:upload_image, :domain_file_id ]
      }
    end

    def available_optional_field_options
      opts = available_field_list
      opts.delete(:email)
      opts.delete(:password)
      opts.delete(:password_confirmation)
      opts.map { |elm| [ elm[1][0],elm[0].to_s ] }.sort
    end

    def available_field_options
      available_field_list.to_a.map { |elm| [ elm[1][0],elm[0].to_s ] }.sort
    end

    def all_field_list
       available_field_list.to_a
    end

    def any_field_list
      flds = available_field_list
      fields = (self.required_fields + self.optional_fields).uniq
      ['password_confirmation','password','email'].each do |fld|
        fields.unshift(fld) if !fields.include?(fld)
      end
      fields.map { |elm| flds[elm.to_sym] ? [ elm.to_sym, flds[elm.to_sym] ] : nil }.compact
    end

    def always_required_fields
      flds = [ 'email', 'password', 'password_confirmation' ]
    end

    def required_field_list
      flds = available_field_list
      fields = (self.required_fields).uniq
      ['password_confirmation','password','email'].each do |fld|
        fields.unshift(fld) if !fields.include?(fld)
      end
      fields.map { |elm| flds[elm.to_sym] ? [ elm.to_sym, flds[elm.to_sym] ] : nil }.compact
    end

    def optional_field_list
      flds = available_field_list
      fields = (self.optional_fields).uniq
      fields.map { |elm| flds[elm.to_sym] ? [ elm.to_sym, flds[elm.to_sym] ] : nil }.compact
    end

    def available_address_field_list
      {
        :company => [ 'Company'.t, :text_field,:company],
        :phone => [ 'Phone'.t, :text_field,:phone],
        :fax => [ 'Fax'.t, :text_field,:fax],
        :address => [ 'Address'.t, :text_field,:address],
        :address_2 => [ 'Address (Line 2)'.t, :text_field,:address_2],
        :city => [ 'City'.t, :text_field,:city],
        :state => [ 'State'.t, :select,:state,{ :options => ContentModel.state_select_options } ],
        :zip => [ 'Zip Code'.t, :text_field,:zip],
	:country => [ 'Country'.t, :country_select, :country]
      }
    end

    def available_address_field_options(business = false)
      flds = available_address_field_list
      if(!business)
        flds.delete(:company)
       end
      flds.to_a.map { |elm| [ elm[1][0],elm[0].to_s ] }.sort
    end

    def address_field_list
      hsh = available_address_field_list
      hsh.delete(:company)
      hsh.to_a
    end

    def business_address_field_list
      available_address_field_list.to_a
    end

    def content_model
      if publication
        @content_mode ||= @pub.conten_model
      else
        nil
      end
    end

    def publication
      @pub ||= ContentPublication.find_by_id(self.content_publication_id)
    end

    def publication_options
      content_model_ids = ContentModelField.find(:all, :conditions => "field_type = 'belongs_to' AND field_module = 'content/core_field'").collect { |fld| fld.content_model_id if fld.relation_class == EndUser }.uniq.compact

      if  content_model_ids.empty?
        []
      else
        ContentPublication.select_options_with_nil('Publication',:conditions => { :publication_type => 'create', :publication_module => 'content/core_publication', :content_model_id => content_model_ids }) unless content_model_ids.empty?
      end
    end

    def publication_field_options
      self.publication.content_model.content_model_fields.find(:all, :conditions => "field_type = 'belongs_to' AND field_module = 'content/core_field'").collect { |elm| [elm.name, elm.field] } if self.publication
    end

    def subscriptions
      @subscriptions ||= self.include_subscriptions.collect do |subscription_id|
        UserSubscription.find_by_id subscription_id
      end.compact
    end

    def self.user_level_options
      UserRegisterOptions.user_level_options
    end
  end

  class LoginOptions < HashModel
    # For feature stuff
    include HandlerActions

    default_options :login_type => 'email',:success_page => nil, :forward_login => 'no',:failure_page => nil, :features => []
    integer_options :success_page, :failure_page
    page_options :success_page, :failure_page
    validates_presence_of :forward_login
    
    options_form(fld(:login_type, :select, :options => :login_type_options),
		 fld(:success_page, :select, :options => :page_options, :label => 'Destination Page'),
		 fld(:failure_page, :select, :options => :page_options, :label => 'Failure Page'),
		 fld(:forward_login, :radio_buttons, :options => :forward_login_options, :description => 'If users were locked out of a previous, forward them back to that page.')
		 )

    def validate
      if !self.features.is_a?(Array)
        self.features = self.features.to_a.sort {  |a,b| a[0] <=> b[0]  }.map {  |elm| obj = Handlers::ParagraphFeature.new(elm[1]);  obj.to_hash }

        self.login_features.each do |feature|
          if !feature.options.valid?
            self.errors.add_to_base('Feature Error')
          end
        end
       
      end
    end

    def options_partial
      nil
    end

    def self.login_type_options
      [['By Email','email'], ['By Username','username'], ['Either','both']]
    end

    def self.page_options
      [[ '--Stay on Same Page--'.t, nil ]] + SiteNode.page_options()
    end

    def self.forward_login_options
      [['Yes','yes'], ['No','no']]
    end

    def available_features
      [['--Select a feature to add--','']] + get_handler_options(:editor,:auth_login_feature)
     end

    def login_features
      @login_features ||= self.features.map do |feature|
        Handlers::ParagraphFeature.new(feature.merge({ :feature_type => 'editor_auth_login_feature'}))
      end
    end
  end

  def enter_vip
    @options = EnterVipOptions.new(params[:enter_vip] || @paragraph.data || {})
    
    if request.post? && params[:enter_vip] && @options.valid?
      @paragraph.data = @options.to_h
      @paragraph.save
      
      render_paragraph_update
      return
    end
    
    @pages = [['--Select Page--'.t, nil ]] + SiteNode.page_options()
  end
  
  class EnterVipOptions < HashModel
    default_options :success_page => nil, :already_registered_page => nil, :login_even_if_registered => false, :add_tags => ''
    validates_presence_of :success_page, :login_even_if_registered

    integer_options :success_page
    boolean_options :login_even_if_registered
    page_options :success_page
  end

  def missing_password
  
    @options = MissingPasswordOptions.new(params[:missing_password] || @paragraph.data || {})
    
    return if handle_paragraph_update(@options)
  
    @mail_templates = [['--Select Mail Template--'.t, nil ]] + MailTemplate.find_select_options(:all)
  end
  
  class MissingPasswordOptions < HashModel
    default_options :email_template => nil, :reset_password_page => nil
    
    integer_options :email_template, :reset_password_page
    page_options :reset_password_page
    
    validates_presence_of :email_template, :reset_password_page
  end
  
  def email_list
    
    @options = EmailListOptions.new(params[:email_list] || @paragraph.data || {})
    
    return if handle_paragraph_update(@options)

    @on_off = [ ['Required','required'],['Optional','optional'],['Off','off']]    
    @subscriptions = [['--Do not use a subscription--','']] + UserSubscription.find_select_options(:all,:order => 'name')
    @pages = [['--Stay on same page--'.t, nil ]] + SiteNode.page_options()
  end
  
  class EmailListOptions < HashModel
    default_options :user_subscription_id => nil, :tags => nil, :zip => 'optional', :first_name => 'off', :last_name => 'off',:destination_page_id => nil, :user_source => nil,
         :success_message => 'Thank you, your email has been added to our list', :partial_post => 'yes'
    
    integer_options :user_subscription_id, :destination_page_id
    page_options :destination_page_id
  end
  
  class SplashOptions < HashModel
    default_options :splash_page_id => nil, :cookie_name => 'splash'
    validates_presence_of :splash_page_id, :cookie_name 
    
    integer_options :splash_page_id
    page_options :splash_page_id
    
    options_form(fld(:splash_page_id, :select, :options => :page_options),
		 fld(:cookie_name, :text_field, :description => 'Name of the splash page cooke (should be different for each splash page')
		 )

    def self.page_options
      [['--Select Splash Page--'.t,nil]] + SiteNode.page_options()
    end
  end


  def add_feature
    @info = get_handler_info(:editor,:auth_user_register_feature,params[:feature_handler])
    
    if @info && myself.editor?
      @feature = Handlers::ParagraphFeature.new({ })
      @feature.feature_handler = @info[:identifier]   
      @feature.feature_type = 'editor_auth_user_register_feature'
      render :partial => 'user_register_feature', :locals => { :feature => @feature, :idx => params[:index] }
    else
      render :nothing => true
    end  
    
  end

  def add_login_feature
    @info = get_handler_info(:editor,:auth_login_feature,params[:feature_handler])
    
    if @info && myself.editor?
      @feature = Handlers::ParagraphFeature.new({ })
      @feature.feature_handler = @info[:identifier]   
      @feature.feature_type = 'editor_auth_login_feature'
      render :partial => 'login_feature', :locals => { :feature => @feature, :idx => params[:index] }
    else
      render :nothing => true
    end  
    
  end

  def add_user_edit_feature
    @info = get_handler_info(:editor,:auth_user_edit_feature,params[:feature_handler])
    
    if @info && myself.editor?
      @feature = Handlers::ParagraphFeature.new({ })
      @feature.feature_handler = @info[:identifier]   
      @feature.feature_type = 'editor_auth_user_edit_feature'
      render :partial => 'user_edit_feature', :locals => { :feature => @feature, :idx => params[:index] }
    else
      render :nothing => true
    end  
    
  end

end
