# Copyright (C) 2009 Pascal Rettig.

class Editor::AuthController < ParagraphController
  permit 'editor_editor'
  
  # Editor for authorization paragraphs
  editor_header "Member Paragraphs", :paragraph_member
  editor_for :login, :name => 'User Login', :features => ['login']
  editor_for :enter_vip, :name => 'Enter VIP #', :features => ['enter_vip'], :triggers => [['Failed VIP Login','failure'],['Successful VIP Login','success' ],['Repeat Successful VIP Login','repeat']]
  editor_for :register, :name => 'User Registration', :triggers => [ ['View Registration Paragraph','view'], ['Successful Registration','action'] ]

  editor_for :edit_account, :name => 'Edit Account', :triggers => [ ['Edit Profile','action' ]] 

 
  editor_for :missing_password, :name => 'Missing Password', :triggers => [ ['Sent Email','action']], :features => ['missing_password']
  
  
  editor_for :email_list, :name => 'Email List Signup', :triggers => [ ['Signed Up','action']], :features => ['email_list']
  editor_for :splash, :name => 'Splash Page'
  

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

end
