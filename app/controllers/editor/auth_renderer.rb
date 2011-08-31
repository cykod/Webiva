# Copyright (C) 2009 Pascal Rettig.

class Editor::AuthRenderer < ParagraphRenderer #:nodoc:all

  features '/editor/auth_feature'

  paragraph :user_register
  paragraph :user_activation
  paragraph :login
  paragraph :enter_vip
  paragraph :missing_password
  paragraph :email_list
  paragraph :splash
  paragraph :view_account
  paragraph :user_edit_account

  def user_register

    @options = paragraph_options(:user_register)

    if !editor? &&  myself.id && @options.already_registered_page_url
      return redirect_paragraph @options.already_registered_page_url
    end

    if myself.id && !editor?
      @registered = true
    else
      @usr = EndUser.new
      @address = @usr.build_address(:address_name => 'Default Address'.t, :country => @options.country )
      @business = @usr.build_work_address(:address_name => 'Business Address'.t, :country => @options.country )
      if request.post? && params[:user] && params[:partial]
        @usr.attributes =  params[:user].slice(*(@options.required_fields + @options.optional_fields + @options.always_required_fields).uniq)
        @address.attributes = params[:address].slice( @options.available_address_field_list.keys) if params[:address]
        @business.attributes = params[:business].slice( @options.available_address_field_list.keys) if params[:business]


      end

      if !request.post? && session[:captured_user_info]
        @usr.attributes = session[:captured_user_info]
        session[:captured_user_info] = nil
      end

      if @options.publication
        @model = @options.publication.content_model.content_model.new
      end
    end

    @options.register_features.each do |feature|
      feature.feature_instance.generate(params)
    end

    @captcha = WebivaCaptcha.new(self) if @options.require_captcha

    if request.post? && params[:user] && !@registered && !params[:partial]
      # See we already have an unregistered user with this email
      @usr = EndUser.find_target(params[:user][:email],:no_create => true)
      
      if @usr.registered?
        # If user is registered we need to create a new user
        @usr = EndUser.new(:source => 'website')
      end

      # Save any tracking information we have already
      @usr.anonymous_tracking_information = myself.anonymous_tracking_information
      
      # Assign a slice of params to the user
      @usr.attributes = params[:user].slice(*(@options.required_fields + @options.optional_fields + @options.always_required_fields).uniq)

      @usr.registered = true if @options.registration_type == 'account'
      @usr.user_class_id = @options.user_class_id if @usr.user_class_id.blank? || @options.modify_profile == 'modify'

      # check everything is valid
      all_valid = true
      @captcha.validate_object(@usr) if @captcha

      @usr.valid?

      # go over each required field - add an error if it's missing
      @options.required_fields.each do |fld|
        if @usr.send(fld).blank?
          @usr.errors.add(fld,'is missing')
        end
      end

      all_valid = false unless @usr.errors.length == 0
     
      # same for address
      all_valid = false unless assign_entry(@address, params[:address], @options.available_address_field_list.keys, @options.address_required_fields)

      # same for business address
      all_valid = false unless assign_entry(@business, params[:business], @options.available_address_field_list.keys, @options.work_address_required_fields)

      if @model
        @options.publication.assign_entry(@model,params[:model],renderer_state)
        all_valid = false unless @model.errors.length == 0
      end
      
      @options.register_features.each do |feature|
        all_valid=false unless feature.feature_instance.valid?
      end


      # if there are no errors on anything
      # save the user,

      @failed = true unless all_valid

      if all_valid 
        set_source_conn, set_source_val = page_connection(:source)

        @usr.lead_source = @options.source unless @options.source.blank?
        @usr.lead_source = set_source_val if set_source_val.present?

        if params[:address]
          @address.save
          @usr.address_id =@address.id
        end

        if params[:business]
          @business.save
          @usr.work_address_id = @business.id
        end

        if @options.require_activation
          @usr.activated = false
          @usr.generate_activation_string
        end

        # Make sure save is successful - will recheck validation and
        # rescan for uniques
        if(@usr.save)
          self.elevate_user_level @usr, @options.user_level

          @usr.tag_names_add(@options.add_tags) unless @options.add_tags.blank?

          add_tags_conn, add_tags_ids = page_connection(:tag)
          if add_tags_ids.present?
            @usr.tag_names_add(add_tags_ids)
            paragraph_action(@usr.action('/editor/auth/registration_tag',:identifier => add_tags_ids))
          end




          session[:user_tracking] = nil

          @address.update_attribute(:end_user_id,@usr.id) if @address.id
          @business.update_attribute(:end_user_id,@usr.id) if @business.id

          if @options.include_subscriptions.is_a?(Array) && @options.include_subscriptions.length > 0
            @options.subscriptions.each do |sub|
              sub.subscribe_user @usr, :ip_address => request.remote_ip
            end
          end

          @options.register_features.each do |feature|
            feature.feature_instance.post_process(@usr)
          end

          if !@options.require_activation
            process_login(@usr)
          end

          if @model
            # Re-update entry as we now have a user object
            @options.publication.assign_entry(@model,params[:model],renderer_state(:user => @usr))
            @model.save
          end

          # run any triggered actions
          paragraph.run_triggered_actions(@usr,'action',@usr)

          # send mail template if we have one
          if @options.registration_template_id.to_i > 0 && @mail_template = MailTemplate.find_by_id(@options.registration_template_id)
            vars = { 

            }
            if @options.require_activation
              url = Configuration.domain_link(@options.activation_page_url + "?code=#{@usr.activation_string}")
              vars['ACTIVATION_URL'] = url
              vars['ACTIVATION_LINK'] = "<a href='#{url}'>#{url}</a>"
            end
            @mail_template.deliver_to_user(@usr,vars)
          end
          
          paragraph_action(@usr.action('/editor/auth/user_registration', :identifier => @usr.email))

          if @options.lockout_redirect &&  session[:lock_lockout]
            lock_logout = session[:lock_lockout]
            session[:lock_lockout] = nil
            redirect_paragraph lock_logout
            return
          elsif @options.success_page_url
            redirect_paragraph @options.success_page_url
            return
          end
          render_paragraph :text => 'Successful Registration'.t 
          return
        end

        
      end
    end

    @field_list = @options.field_list

    @feature = { }
    
    @options.register_features.each do |feature|
      feature.feature_instance.feature_data(@feature)
    end

    render_paragraph :feature => :user_register
  end

  def user_edit_account
    @options = paragraph_options(:user_edit_account)

    if myself.id
      @usr = myself
      @address = @usr.address ||  @usr.build_address(:address_name => 'Default Address'.t, :country => @options.country )
      @business = @usr.work_address ||  @usr.build_work_address(:address_name => 'Business Address'.t, :country => @options.country )

      if @options.publication
        field = @options.content_publication_user_field
        model_class = @options.publication.content_model.model_class
        @model = model_class.find(:first, :conditions => {field.to_sym => myself.id}) || model_class.new(field.to_sym => myself.id)
      end
    end

    @feature = { }


    @options.user_edit_features.each do |feature|
      feature.feature_instance.generate(params,@usr)
    end


    if request.post? && ( params[:user] || params[:model] ) && !editor? && myself.id
      params[:user] ||= {}
      handle_image_upload(params[:user],:domain_file_id)
      # Assign a slice of params to the user
      @usr.attributes = params[:user].slice(*(@options.required_fields + @options.optional_fields + @options.always_required_fields).uniq)
      unless @usr.editor?
        @usr.user_class_id = @options.user_class_id if @usr.user_class_id.blank? || @options.modify_profile == 'modify'
      end

      # check everything is valid
      all_valid = true
      @usr.valid?

      # go over each required field - add an error if it's missing
      @options.required_fields.each do |fld|
        if @usr.send(fld).blank?
          @usr.errors.add(fld,'is missing')
        end
      end


      all_valid = false unless @usr.errors.length == 0

      # same for address
      all_valid = false unless assign_entry(@address, params[:address], @options.available_address_field_list.keys, @options.address_required_fields)

      # same for business address
      all_valid = false unless assign_entry(@business, params[:business], @options.available_address_field_list.keys, @options.work_address_required_fields)

      if @model
        @options.publication.assign_entry(@model,params[:model],renderer_state)
        all_valid = false unless @model.errors.length == 0
      end

      @options.user_edit_features.each do |feature|
        all_valid=false unless feature.feature_instance.valid?
      end


    
      # if there are no errors on anything
      # save the user,
      @failed = true unless all_valid

      if all_valid 

        if params[:address]
          @address.save
          @usr.address_id = @address.id
        end

        if params[:business]
          @business.save
          @usr.work_address_id = @business.id
        end

        # Make sure save is sucessful - will recheck validation and
        # rescan for uniques
        if(@usr.save)
          self.elevate_user_level @usr, @options.user_level

          @usr.tag_names_add(@options.add_tags) unless @options.add_tags.blank?

          @address.update_attribute(:end_user_id,@usr.id) if @address.id
          @business.update_attribute(:end_user_id,@usr.id) if @business.id

          if @options.include_subscriptions.is_a?(Array) && @options.include_subscriptions.length > 0
            @options.subscriptions.each do |sub|
              sub.subscribe_user @usr, :ip_address => request.remote_ip
            end
          end

          @model.save if @model

          @options.user_edit_features.each do |feature|
            feature.feature_instance.post_process(@usr)
          end


          if @options.access_token_id
            tkn = AccessToken.find_by_id(@options.access_token_id)
            @usr.add_token!(tkn) if tkn
          end
          # run any triggered actions
          paragraph.run_triggered_actions(@usr,'action',@usr)

          # send mail template if we have one
          if @options.mail_template_id.to_i > 0 && @mail_template = MailTemplate.find_by_id(@options.mail_template_id)
            vars = {}
            @mail_template.deliver_to_user(@usr,vars)
          end

          paragraph_action(@usr.action('/editor/auth/user_edit_account', :identifier => @usr.email))

          if @options.success_page_url
            redirect_paragraph @options.success_page_url
            return
          end

          flash[:notice] = 'Account Updated'.t
          @updated = true
        end
      end
    end

    @reset_password = flash['reset_password']

    @options.user_edit_features.each do |feature|
      feature.feature_instance.feature_data(@feature)
    end


    render_paragraph :feature => :user_edit_account
  end

  def login
    opts = paragraph_options(:login)

    opts.login_features.each do |feature|
      return if feature.feature_instance.logged_in(self, opts)
    end

    data = {}
    if myself.id
      data[:user] = myself
    end

    data[:login_user] = myself
    data[:options] = opts
    data[:current_page] = paragraph_page_url
    data[:logout_url] = "#{data[:current_page]}?cms_logout=1"

    if params[:cms_logout]
      opts.login_features.each do |feature|
        feature.feature_instance.logout
      end

       paragraph_action(myself.action('/editor/auth/logout'))
       process_logout
       redirect_paragraph :page
       return
    elsif request.post? && !editor?
      if(params[:cms_login] && params[:cms_login][:password] && (params[:cms_login][:login] || params[:cms_login][:username]))
        if opts.login_type == 'email' || opts.login_type == 'both'
          user = EndUser.login_by_email(params[:cms_login][:login],params[:cms_login][:password])
          user ||= EndUser.login_by_username(params[:cms_login][:login],params[:cms_login][:password]) unless user || opts.login_type == 'email'
        else
          user = EndUser.login_by_username(params[:cms_login][:username],params[:cms_login][:password])
        end
        
        if myself.id && user
          process_logout
          redirect_paragraph paragraph_page_url
          return
        end
        if user
          process_login(user,params[:cms_login][:remember].to_s == '1')
          paragraph_action(myself.action('/editor/auth/login'))
         
          if opts.forward_login == 'yes' && session[:lock_lockout]
              lock_logout = session[:lock_lockout]
              session[:lock_lockout] = nil
              redirect_paragraph lock_logout
              return
          elsif opts.success_page
            nd = SiteNode.find_by_id(opts.success_page)
            if nd
              redirect_paragraph nd.node_path
              return
            end
          end
          redirect_paragraph :page
          return
        else
          if(opts.failure_page.to_i > 0)
              flash[:auth_user_login_error] = true
              redirect_paragraph :site_node => opts.failure_page.to_i
              return
          else
            data[:error] = true
          end
        end
      else
        opts.login_features.each do |feature|
          return if feature.feature_instance.login(params)
        end
      end
    end
    data[:error] = true if flash[:auth_user_login_error]
    data[:type] = opts.login_type

    @feature = { }

    opts.login_features.each do |feature|
      feature.feature_instance.feature_data(@feature)
    end

    data[:feature] = @feature

    render_paragraph :text => login_feature(data)
  end

  def user_activation
    @options = paragraph_options(:user_activation)

    code = params[:activate] ? params[:activate][:code]  : params[:code]

    @user = EndUser.find_by_activation_string(code) unless code.to_s.strip.blank?
    if editor? 
      @user = EndUser.find(:first,:conditions => {  :activated => false })
    end

    if @user && @user.activated?
      @status = 'already_activated'
      if @options.already_activated_redirect_page_id
        redirect_paragraph @options.already_activated_redirect_page_url
        return
      end
    elsif @user
      @status = 'activation'
      
      if !@options.require_acceptance
        @status ='activated'
      end

    else
      @status = 'invalid'
    end

    if !editor? && @user && ( (request.post? && params[:activate]) || @status == 'activated' )
      if @status == 'activation' && params[:activate][:accept].blank?
        @acceptance_error = true
      
      elsif @user.update_attributes(:activated => true)
        @status ='activated'

        process_login(@user) if @options.login_after_activation

        paragraph.run_triggered_actions(myself,'action',myself)

        if @options.redirect_page_id
          redirect_paragraph @options.redirect_page_url
          return
        end
      end
    end

    if @status == 'activation'
      @activation_object = DefaultsHashObject.new(:code => code, :accept => false )
    end

    render_paragraph :feature => :user_activation
  end
  
  
  def enter_vip
    opts = paragraph_options(:enter_vip)
  
    return render_paragraph :text => enter_vip_feature(:failure => false, :registered => false) if editor?

    data = { :failure => false, :registered => myself.registered? }

    if request.post? && params[:vip] && !params[:vip][:number].blank?
      vip_number = params[:vip][:number]
      
      user = EndUser.find_by_vip_number(vip_number)
      if user
        # Must be VIP # for unregistered user, or paragraph must allow it
        if !user.registered? || opts.login_even_if_registered
          
          process_login user
          
	  paragraph_action(myself.action('/editor/auth/enter_vip_success', :identifier => vip_number))
          paragraph.run_triggered_actions(myself,'success',myself)
          
          user.update_attribute(:user_level, 2) if user.user_level < 2
          
          if !opts.add_tags.to_s.empty?
            user.tag_names_add(opts.add_tags)
          end
          
          @nd = SiteNode.find_by_id(opts.already_registered_page) if user.registered? && opts.already_registered_page
          
          @nd = SiteNode.find_by_id(opts.success_page) unless @nd
          if @nd 
            redirect_paragraph @nd.node_path
            return 
	  end
        else
	  paragraph_action(myself.action('/editor/auth/enter_vip_repeat', :identifier => vip_number))
	  paragraph.run_triggered_actions(myself,'repeat',myself)
          data[:registered] = true
        end
      else
	paragraph_action(myself.action('/editor/auth/enter_vip_failure', :identifier => vip_number))
	paragraph.run_triggered_actions(myself,'failure',EndUser.new(:vip_number => vip_number))
        data[:failure] = true
      end
    end
    
    render_paragraph :text => enter_vip_feature(data)  
  end

  # update users subscriptions
  def update_subscriptions(user,available_subscriptions,subscriptions)

    subscription_conditions = "user_subscription_id IN (#{available_subscriptions.collect {|sub| DomainModel.connection.quote(sub) }.join(",")})"
    user_subscription_conditions = "id IN (#{available_subscriptions.collect {|sub| DomainModel.connection.quote(sub) }.join(",")})"
    # Make sure we are updating subscriptions
    if subscriptions && subscriptions['0']

      user_subscriptions = user.user_subscription_entries.find(:all,:conditions => subscription_conditions).index_by(&:user_subscription_id)
      UserSubscription.find(:all,:conditions => user_subscription_conditions).each do |sub|
        # Now create an remove subscriptions as necessary
        if subscriptions[sub.id.to_s] && !user_subscriptions[sub.id]
           sub.subscribe_user(user)
        elsif !subscriptions[sub.id.to_s] && user_subscriptions[sub.id]
           user_subscriptions[sub.id].destroy
        end
      end
    end
  end

  def missing_password
    options = paragraph_options(:missing_password)
    
    @page_state = 'missing_password'
    
    if params[:verification]
      user = EndUser.login_by_verification(params[:verification])
      if user
        process_login user

        flash['reset_password'] = true
        redirect_paragraph SiteNode.get_node_path(options.reset_password_page,'#')
        return
      else
        @invalid_verification = true
      end
    elsif request.post? && params[:missing_password] && params[:missing_password][:email] 
      usr = nil
      EndUser.transaction do
        usr = EndUser.find_by_email(params[:missing_password][:email])
        if usr
          usr.update_verification_string!
        end        
      end

      email_template = MailTemplate.find(options.email_template)

      if usr && email_template
        vars = { :verification => Configuration.domain_link(site_node.node_path + "?verification=" + usr.verification_string) }

        MailTemplateMailer.deliver_to_user(usr,email_template,vars)
      end

      flash['template_sent'] = true
      redirect_paragraph :page
      return
    elsif flash['template_sent']
      @page_state = 'template_sent'
    end      
    
    data = { :invalid => @invalid_verification, :state => @page_state }
    
    render_paragraph :text =>  missing_password_feature(data)
  end

  def email_list
    @options = paragraph_options(:email_list)
    
    @user = EmailListUser.new(params["email_list_#{paragraph.id}"] || params[:email_list_signup])
    if (request.post? || params[:get_post]) && (params["email_list_#{paragraph.id}"]  ||  params[:email_list_signup])
      @user.valid?
      
      unless @options.partial_post == 'yes' && params[:partial_post]
        %w(zip first_name last_name).each do |fld|
          @user.errors.add(fld,'is missing') if @options.send(fld) == 'required' && @user.send(fld).blank?
        end
      end
      
      if @user.errors.empty?
        @target = EndUser.find_target(@user.email, :source => 'website')
        if !@target.registered?
          @target.anonymous_tracking_information = myself.anonymous_tracking_information
          @target.first_name = @user.first_name if !@user.first_name.blank? && @options.first_name != 'off'
          @target.last_name = @user.last_name if !@user.last_name.blank? && @options.last_name != 'off'
          if @target.lead_source.blank?
            conn_type,conn_id = page_connection
            @target.lead_source = conn_id if conn_type == :source 
            @target.lead_source = @options.user_source if @target.lead_source.blank? 
          end
          @target.save
          if @options.zip != 'off' 
            adr = @target.address || EndUserAddress.new
	    adr.end_user_id = @target.id
            adr.zip = @user.zip 
            adr.save
            if !@target.address
              @target.update_attribute(:address_id,adr.id)
            end
          end
        end

        self.elevate_user_level @target, EndUser::UserLevel::SUBSCRIBED
        self.visiting_end_user_id = @target.id

        # Handle Subscription
        if @options.user_subscription_id
          sub = UserSubscription.find_by_id(@options.user_subscription_id)
          sub.subscribe_user(@target,:ip_address => request.remote_ip) if sub
        end
        
        unless @options.tags.blank?
          @target.tag_names_add(@options.tags)
        end

        if !editor? && paragraph.update_action_count > 0
          paragraph.run_triggered_actions(@target,'action',@target)
        end
        
        unless @options.partial_post == 'yes' && params[:partial_post]
          if @options.destination_page_id 
            redirect_paragraph :site_node => @options.destination_page_id
            return
          else
            @submitted = @options.success_message
          end
        end
        
      end
      
    end

    render_paragraph :text => email_list_feature(:email_list => @user,
                                                 :options => @options,
                                                 :submitted => @submitted)
  end
  
  class EmailListUser < HashModel
    default_options :email => nil,:zip => nil, :first_name => nil, :last_name => nil
    validates_presence_of :email
    validates_as_email :email
  end
  
  def splash
    options = Editor::AuthController::SplashOptions.new(paragraph.data||{})
    
    if !options.splash_page_id || options.cookie_name.blank?
      if editor? 
        render_paragraph :text => 'Configure Paragraph'
      else
        render_paragraph :nothing => true
      end
      return 
    end 

    if editor?
      render_paragraph :text => '[Splash Page]'
    else
      if params[:no_splash]
        cookies[options.cookie_name.to_sym]= { :value => 'set', :expires => 1.year.from_now }
        render_paragraph :nothing => true
      elsif cookies[options.cookie_name.to_sym]
        render_paragraph :nothing => true
      else
        cookies[options.cookie_name.to_sym]= { :value => 'set', :expires => 1.year.from_now }
        url = options.splash_page_url.to_s

        if params["_source"]
          url << "?_source=#{CGI.escape(params["_source"])}"
        end

        redirect_paragraph url
      end
    end   
  end

  def view_account
    @user = myself
    render_paragraph :feature => :view_account
  end

  protected

  def assign_entry(model, data, available_fields, required_fields)
    if data || required_fields.length > 0
      model.attributes = (data||{}).slice(*available_fields)
      model.valid?

      required_fields.each do |fld|
        if model.send(fld.to_sym).blank?
          model.errors.add(fld.to_sym, 'is missing')
        end
      end

      model.errors.length == 0
    else
      true
    end
  end
end
