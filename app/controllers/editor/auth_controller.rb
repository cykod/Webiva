# Copyright (C) 2009 Pascal Rettig.

class Editor::AuthController < ParagraphController #:nodoc:all
  permit 'editor_editor'
  
  user_actions [:add_feature ]

  # Editor for authorization paragraphs
  editor_header "Member Paragraphs", :paragraph_member
  editor_for :login, :name => 'User Login', :features => ['login']
  editor_for :enter_vip, :name => 'Enter VIP #', :features => ['enter_vip'], :triggers => [['Failed VIP Login','failure'],['Successful VIP Login','success' ],['Repeat Successful VIP Login','repeat']]

  editor_for :user_register, :name => 'User Registration', :feature => 'user_register', :triggers => [ ['Successful Registration','action'] ]

  editor_for :user_activation, :name => 'User Activation', :feature => 'user_activation', :triggers => [ ['Successful Activation','action'] ]

  editor_for :edit_account, :name => 'Edit Account', :triggers => [ ['Edit Profile','action' ]] 

 
  editor_for :missing_password, :name => 'Missing Password', :triggers => [ ['Sent Email','action']], :features => ['missing_password']
  
  
  editor_for :email_list, :name => 'Email List Signup', :triggers => [ ['Signed Up','action']], :features => ['email_list']
  editor_for :splash, :name => 'Splash Page'


  
  editor_for :register, :name => 'Legacy User Registration', :triggers => [ ['View Registration Paragraph','view'], ['Successful Registration','action'] ], :legacy => true


  
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
    :features => []

    boolean_options :lockout_redirect, :require_activation

    page_options :success_page_id, :activation_page_id 
   
    validates_presence_of :success_page_id, :user_class_id


    def validate
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
        :last_name => ['Last Name'.t,:text_field,:last_name],
        :gender => ['Gender'.t, :radio_buttons, :gender, { :options => [ ['Male'.t,'m'],['Female'.t,'f' ] ] } ],
        :introduction => ['Introduction'.t, :radio_buttons, :gender, { :options => [ ['Mr.'.t,'Mr.'],['Mrs.'.t,'Mrs' ], ['Ms.'.t, 'Ms'] ] } ],
        :username => [ 'Username'.t,:text_field, :username ],
        :salutation => [ 'Salutation'.t,:text_field, :salutation ]
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
      ['password','password_confirmation','email'].each do |fld|
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
        :state => [ 'State'.t, :select,:state,{ :options => ContentModel.state_select_options } ],
        :zip => [ 'Zip Code'.t, :text_field,:zip]
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

  end

  class UserActivationOptions < HashModel
    attributes :require_acceptance => false, :redirect_page_id => nil, 
      :already_activated_redirect_page_url => nil, :login_after_activation => false

    page_options :redirect_page_id, :already_activated_redirect_page_id
    boolean_options :require_acceptance, :login_after_activation
  end


  def login
      @options = LoginOptions.new(params[:login] || @paragraph.data || {})
      
      return if handle_paragraph_update(@options)
      @pages = [[ '--Stay on Same Page--'.t, nil ]] + SiteNode.page_options()
  end
  
  class LoginOptions < HashModel
      default_options :login_type => 'email',:success_page => nil, :forward_login => 'no',:failure_page => nil
      integer_options :success_page, :failure_page
      validates_presence_of :forward_login
  end
  
  


  def edit_account
     @options = EditAccountOptions.new(params[:edit_profile] || @paragraph.data || {})
    
    if request.post? && @options.valid?
      if @options.include_subscriptions.is_a?(Array)
         @options.include_subscriptions = @options.include_subscriptions.find_all { |elem| !elem.blank? }.collect { |elem| elem.to_i } 
      else
        @options.include_subscriptions = []
      end
      @options.success_page = @options.success_page.to_i
      @paragraph.data = @options.to_h
      @paragraph.save
      render_paragraph_update
      return
    end

    @content_publications = [ ['No Publication', 0 ] ] + ContentPublication.find(:all,:conditions => 'publication_type = "create"',:order => 'content_models.name, content_publications.name',
                                                    :include => :content_model ).collect { |pub| [ pub.content_model.name + ' - ' + pub.name, pub.id ] }
  
    @pages = [[ '--Select Page--'.t, nil ]] + SiteNode.page_options()
  
    @fields = %w{username gender first_name last_name dob address work_address}
    @field_options = [ [ 'Required', 'required' ], [ 'Optional','optional' ], ['Do not Display','off' ] ]
    @subscriptions = UserSubscription.find_select_options(:all,:order => 'name')
  end
  
  class EditAccountOptions < HashModel
    default_options :success_page => nil, :form_display => 'normal', :first_name => 'required', :last_name => 'required', 
                    :gender => 'required', :username => 'off', :dob => 'off', :address => 'off', :work_address => 'off', :add_tags => '',
                     :include_subscriptions => [],  :country => 'United States', :reset_password => 'show',
                    :address_type => 'us', :edit_button => nil
    validates_presence_of :success_page
  end  

  def enter_vip
    @options = VipEnterOptions.new(params[:vip] || @paragraph.data || {})
    
    if request.post? && params[:vip] && @options.valid?
      @options.success_page = @options.success_page.to_i
      @options.login_even_if_registered = @options.login_even_if_registered.to_i == 1 ?  true  : false
      
      @paragraph.data = @options.to_h
      @paragraph.save
      
      render_paragraph_update
      return
    end
    
    @pages = [['--Select Page--'.t, nil ]] + SiteNode.page_options()
  
  end
  
  class VipEnterOptions < HashModel
    default_options :success_page => nil, :already_registered_page => nil, :login_even_if_registered => false, :add_tags => ''
    
    validates_presence_of :success_page, :login_even_if_registered
  end

  def email_friend
      @options = EmailFriendOptions.new(params[:email_friend] || @paragraph.data || {})

    return if handle_paragraph_update(@options)    
    
    @pages = [['Stay on same page'.t, nil ]] + SiteNode.page_options()
    @mail_templates = [['--Select Mail Template--'.t, nil ]] + MailTemplate.find_select_options(:all)
  end

  class EmailFriendOptions < HashModel
    default_options :email_template => nil, :success_page => nil, :send_type => 'template', :default_message_text => 'Click to enter a personalize message', :clear_message => 'yes', :message_subject => nil, :email_limit => 20, :ip_limit => 100
    
    integer_options  :success_page, :email_template
    
    validates_presence_of :email_template
  end
  
  def email_friend_link
    @options = EmailFriendLinkOptions.new(params[:email_friend_link] || @paragraph.data || {})
    
    return if handle_paragraph_update(@options)
    
    @pages = [['--Select email friend page--'.t, nil ]] + SiteNode.page_options()
  end
  
  class EmailFriendLinkOptions < HashModel
    default_options :destination_page_id => nil
    
    integer_options :destination_page_id
    
    validates_presence_of :destination_page_id
  end

  def missing_password
  
    @options = MissingPasswordOptions.new(params[:missing_password] || @paragraph.data || {})
    
    return if handle_paragraph_update(@options)
  
    @mail_templates = [['--Select Mail Template--'.t, nil ]] + MailTemplate.find_select_options(:all)
  end
  
  class MissingPasswordOptions < HashModel
    default_options :email_template => nil, :reset_password_page => nil
    
    integer_options :email_template, :reset_password_page
    
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
  end
  
  def splash
    @options = SplashOptions.new(params[:splash] || @paragraph.data || {})
    
    return if handle_paragraph_update(@options)
    
    @pages = [['--Select Splash Page--'.t,nil]] + SiteNode.page_options()
  
  end
  
  class SplashOptions < HashModel
    default_options :splash_page_id => nil, :cookie_name => 'splash'
    validates_presence_of :splash_page_id, :cookie_name 
    
    integer_options :splash_page_id 
  
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







  # LEGACY PARAGRAPHS


  def register
  
    @options = RegisterOptions.new(params[:register] || @paragraph.data || {})
    
    if request.post? && @options.valid?
      if @options.include_subscriptions.is_a?(Array)
         @options.include_subscriptions = @options.include_subscriptions.find_all { |elem| !elem.blank? }.collect { |elem| elem.to_i } 
      else
        @options.include_subscriptions = []
      end
      
      @paragraph.data = @options.to_h
      @paragraph.save
      render_paragraph_update
      return
    end

    @content_publications = [ ['No Publication', 0 ] ] + ContentPublication.find(:all,:conditions => 'publication_type = "create"',:order => 'content_models.name, content_publications.name',
                                                     :include => :content_model ).collect { |pub| [ pub.content_model.name + ' - ' + pub.name, pub.id ] }
    
      @pages = [[ '--Select Page--'.t, nil ]] + SiteNode.page_options()
    
      @fields = %w{username membership gender first_name last_name dob address work_address work_fax referrer captcha}
      @field_options = [ [ 'Required', 'required' ], [ 'Optional','optional' ], ['Do not Display','off' ] ]
     @subscriptions = UserSubscription.find_select_options(:all,:order => 'name')
  end
  
  class RegisterOptions < HashModel
    default_options :success_page => nil, :content_publication => nil, :registration_type => 'login', :form_display => 'normal', :already_registered_redirect => nil, :user_class_id => nil, :username => 'off', :first_name => 'required', :last_name => 'required', :modify_profile => 'modify', :referrer => 'off', :membership => 'off',
                    :gender => 'required', :dob => 'off', :address => 'off', :work_address => 'off', :add_tags => '', :work_fax => 'off',
                    :site_policy => 'off', :policy_text => '', :registration_template => nil, :include_subscriptions => [], :clear_info => 'n', :country => 'United States',
                    :address_type => 'us', :registration_button => nil, :captcha => 'off'
    integer_options :success_page, :already_registered_redirect, :user_class_id, :content_publication ,:registration_template
    validates_presence_of :success_page
  end    
end
