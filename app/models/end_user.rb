# Copyright (C) 2009 Pascal Rettig.

require 'digest/sha1'

# User Levels:
# 0 - Opt-Out
# 1 - Manually Added
# 2 - Visited
# 3 - Subscribed 
# 4 - Lead
# 5 - Conversion
# 6 - Superstar


# Sources:
# website
# import
# referral

=begin rdoc
EndUser's are the primary user class inside of Webiva and 
are the primary class you interact with when dealing with 
site users. 
an EndUser doesn't necessarily need to be someone who is
registered w/ an active account on the system - they can be
added via email lists, manually via imports, or via online registration.

The only real required field is an email address, all other fields are
optional. Although they can be made required at signup.

The easiest way to create an EndUser is to use the EndUser#self.push_target method,
for example:

        @user = EndUser.push_target('example@domain.com', :name => 'Svend Karlson')

This will return either an existing user with the specified email address or a newly-saved
user object. See the method's description for more details.



=end
class EndUser < DomainModel

   include ModelExtension::EndUserImportExtension
   include WebivaCaptcha::ModelSupport


  validates_confirmation_of :password

  # Only need an email if we aren't a client user
  validates_presence_of :email, :if => Proc.new { |usr| !usr.client_user_id && !usr.admin_edit }

  validates_format_of :username, :with => /^([ a-zA-Z0-9!#\$%^&*@()_\-.]{2,32})$/,:allow_blank => true, 
                      :message => 'must be 2-32 numbers, letters, and the symbols: !@#$%^&()-_.'

  validates_length_of :password, :minimum => 4, :allow_blank => true, :message => "must be at least 4 letters long"
  # Email always needs to be unique - but can be blank if user is an client user
  validates_uniqueness_of :email,:allow_blank => true
  validates_uniqueness_of :username, :allow_blank => true
  validates_presence_of :user_class
  validates_as_email :email
  
  attr_accessor :admin_edit
  attr_accessor :password
  attr_accessor :site_policy

  attr_reader :login
  
  has_domain_file :domain_file_id
  has_domain_file :second_image_id
  
  belongs_to :address, :class_name => 'EndUserAddress', :foreign_key => :address_id
  belongs_to :shipping_address, :class_name => 'EndUserAddress', :foreign_key => :shipping_address_id
  belongs_to :billing_address, :class_name => 'EndUserAddress', :foreign_key => :billing_address_id
  belongs_to :work_address, :class_name => 'EndUserAddress', :foreign_key => :work_address_id
  has_many :addresses, :class_name => 'EndUserAddress', :dependent => :destroy

  has_one :end_user_cache, :dependent => :delete, :class_name => 'EndUserCache'

  has_many :end_user_cookies, :dependent => :delete_all, :class_name => 'EndUserCookie'
  has_many :api_tokens, :class_name => 'EndUserCookie', :conditions => 'valid_until IS NULL'

  has_many :end_user_actions, :dependent => :delete_all

  has_many :end_user_tokens, :dependent => :delete_all, :include => [ :access_token ]

  has_many :access_tokens, :through => :end_user_tokens

  has_many :end_user_notes, :order => 'created_at DESC'

  has_many :end_user_tags
  has_many :tags, :through => :end_user_tags
  after_save :tag_cache_after_save
  include ContentTagFunctionality
  
  belongs_to :source_user, :class_name => 'EndUser'
  
  has_many :user_subscriptions, :through => :user_subscription_entries
  has_many :user_subscription_entries, :dependent => :destroy
  
  has_many :domain_emails

  attr_accessor :remember

  belongs_to :user_class
 
  attr_protected :client_user_id
  attr_protected :user_class_id
  attr_accessor :email_confirmation

  accepts_nested_attributes_for :end_user_tokens

  has_options :introduction, ['Mr.','Mrs.','Ms.']
  
  module UserLevel
    OPT_OUT = 0
    IMPORTED = 1
    VISITED = 2
    SUBSCRIBED = 3
    LEAD = 4
    CONVERSION = 5
    HIGH_VALUE = 6
  end

  has_options :user_level,
    [['0 - Opt-Out',        UserLevel::OPT_OUT], 
     ['1 - Added Manually', UserLevel::IMPORTED],
     ['2 - Visited',        UserLevel::VISITED],
     ['3 - Subscribed',     UserLevel::SUBSCRIBED],
     ['4 - Lead',           UserLevel::LEAD],
     ['5 - Converison',     UserLevel::CONVERSION],
     ['6 - High-value',     UserLevel::HIGH_VALUE]
    ]

  # Referred to as Origin
  has_options :source, [ [ 'Website', 'website' ],
                         [ 'Import', 'import' ],
                         [ 'Referral', 'referral' ] ]

  if CMS_EDITOR_LOGIN_SUPPORT 
   after_save :update_editor_login
  end

  def after_save #:nodoc:
    self.end_user_cache = EndUserCache.find_by_end_user_id(self.id) unless self.end_user_cache
    self.end_user_cache ? self.end_user_cache.save : EndUserCache.create(:end_user_id => self.id)
  end

  ## Validation Fucntions 
  
  
  def before_validation #:nodoc:
    self.email = self.email.to_s.strip
    self.user_class_id = UserClass.default_user_class_id if self.user_class_id.blank?
    self.email = self.email.downcase unless self.email.blank?
  end

  def validate #:nodoc:
    if self.registered? && !self.hashed_password && (!self.password || self.password.empty?)
      errors.add(:password, 'is missing')
    end

    self.errors.add(:referral, 'is invalid') if @referral && ! self.source_user
  end

  def validate_password(pw) #:nodoc:
    return EndUser.hash_password(pw,self.salt) == self.hashed_password
  end

  def update_verification_string! #:nodoc:
    self.update_attribute(:verification_string, Digest::SHA1.hexdigest(Time.now.to_s + rand(1000000000000).to_s)[0..12])
  end

  def self.find_by_api_token(api_token)
    token = EndUserCookie.find_by_cookie(api_token, :conditions => { :valid_until => nil })
    token.end_user if token
  end

  def api_token
    @api_token ||= (self.api_tokens[0] && self.api_tokens[0].cookie) || EndUserCookie.generate_api_key(self)
  end

  # Is this a administrative ClientUser
  def client_user?
    client_user_id.to_i > 0
  end

  # return an associated ClientUser object if one exists
  # (ClientUser is a SystemModel class)
  def client_user
    return @client_user if @client_user
    return nil unless client_user_id
    @client_user = ClientUser.find_by_id(client_user_id)
  end

  # return an associated Client object if one exists
  # (Client is a SystemModel class)
  def client
    self.client_user ? self.client_user.client : nil
  end

  # Return an Array of subscription ids
  def subscriptions
      self.user_subscriptions.collect { |sub| sub.id }
  end


  ## Access Token Stuff

  def tokens #:nodoc:
    through_connection_cache(:end_user_tokens,@access_token_cache)
  end

  def tokens=(val) #:nodoc:
    @access_token_cache = val
  end

  def has_token?(token)
    token = token.id if token.is_a?(AccessToken)
    self.end_user_tokens.active.find_by_access_token_id(token)
  end

  after_save :token_cache_update

  def token_cache_update #:nodoc:
    if(@access_token_cache)
      set_through_collection_with_attributes(:end_user_tokens,:access_token_id,@access_token_cache)
    end
  end

  # Immediately add a token to a user
  # valid options are:
  # [:valid_until]
  #   Date the token should be valid until
  # [:target]
  #   Target to check for access on this token
  # [:valid_at]
  #   Date this token will start being valid
  def add_token!(tkn,options = { }) 
    eut = self.end_user_tokens.find_by_access_token_id(tkn.id) ||
      self.end_user_tokens.create(:access_token_id => tkn.id)

    # If we are setting any additional options,
    # then override the existing endusertoken
    if options.has_key?(:valid_until) || options.has_key?(:target) || options.has_key?(:valid_at)
      eut.update_attributes(options.slice(:valid_until,:target,:valid_at))
    end
  end

  # Return a list of select options of all users
  def self.select_options(editor=false)
    self.find(:all, :order => 'last_name, first_name',:include => :user_class,
              :conditions => [ 'user_classes.editor = ?',editor ] ).collect { |usr| [ "#{usr.last_name}, #{usr.first_name} (##{usr.id})", usr.id ] } 
  end
  
  # Return the image associated with this user or return the missing_image configured
  # in Website contribution
  def image
    self.domain_file ? self.domain_file : Configuration.missing_image(self.gender)
  end
  
  
  def identifier_name #:nodoc:
    self.name + " (#{self.id})"
  end
  
  # Is this user a site editor?
  def editor?
    self.user_profile.editor?
  end
  
  serialize :options
  
  include VerifiedModel
  
  # Get user class, otherwise just the first (anonymous) user class
  def user_profile
    self.user_class || UserClass.anonymous_class
  end

  # Return this users UserClass id, otherwise return the anonymous id
  def user_profile_id
    self.user_class_id || UserClass.anonymous_class_id
  end


  ## Action Functionality

  # Log an action taken by this user
  # see EndUserAction for more details
  def action(action_path,opts = {})
    opts[:level] ||= 3
    EndUserAction.log_action(self,action_path,opts)
  end

  # Log a custom action taken by this user (this can have a custom identifier string)
  def custom_action(action_name,description, opts = {})
    EndUserAction.log_custom_action(self,action_name,description,opts)
  end
  ## Login Functions
  

  # Given a email and a password, return a registered and active EndUser 
  # that matches those account details
  def self.login_by_email(email,password)
    usr = find(:first,:conditions => ["email != '' AND email = ? AND activated = 1 AND registered = 1",email.to_s.downcase] )
    
    hashed_password = EndUser.hash_password(password || "",usr.salt) if usr
    if usr && usr.hashed_password == hashed_password
        usr
    else
      nil
    end
  end  
  
  # Given a username and a password, return a registered and active EndUser 
  # that matches those account details
  def self.login_by_username(username,password)
    usr = find(:first,
         :conditions => ["username != '' AND username = ? and activated = 1 AND registered = 1", username])
    hashed_password = EndUser.hash_password(password || "",usr.salt) if usr
    if usr && usr.hashed_password  == hashed_password
      usr
    else
      nil
    end
  end  

  # Login via a one-time verification string - used to reset a users password via an email ink
  def self.login_by_verification(verification)
    return nil if verification.blank?
    usr=nil
    EndUser.transaction do
      usr = EndUser.find_by_verification_string(verification,:conditions => {  :activated => 1, :registered => 1 })
      if usr
        usr.update_attribute(:verification_string,nil)
      end
    end
    usr
  end
  
  # deprecated
  def self.find_visited_target(email) #:nodoc:
    EndUser.find_by_email_and_registered(email, false) || EndUser.create(:email => email,
									 :user_level => 2,
									 :source => 'website',
									 :registered => false )
  end
  
  def update_domain_emails #:nodoc:
    self.domain_emails.each { |email| email.save }
  end

  # Returns a list of role ids representing the 
  # roles this user has
  def roles_list
    return @roles_list if @roles_list

    @roles_list = self.user_profile.cached_role_ids
    @roles_list += self.end_user_tokens.active.inject([]) do |arr,elm| 
      if elm.target_type.blank?
        arr += elm.access_token.cached_role_ids
      elsif elm.target
        if elm.target.token_valid?
          arr += elm.access_token.cached_role_ids
        else
          arr
        end
      else
        arr
      end
    end
    
    @roles_list
  end
  
  # Checks if a user has any of the expanded roles passed in
  # as an array of Role objects
  def has_any_role?(expanded_roles)
    r = expanded_roles.find { |role| return true if has_role?(role) }
    false
  end

  # Checks if a user has end of the expanded roles passed in
  # as an array of Role objects
  def has_all_roles?(expanded_roles)
    expanded_roles.each { |role| return false unless has_role?(role) }
    true
  end

  # Checks if this user has a certain role (not expanded) on an optional target
  def has_role?(role,target=nil)
    if(self.client_user_id && self.user_class_id == UserClass.client_user_class_id)
      role = role.to_s
      case role
      when 'system_admin'
        self.client_user.system_admin?
      when 'client_admin'
        self.client_user.system_admin? || self.client_user.client_admin?
      else
        return false unless self.client_user.system_admin? || self.client_user.client_admin? || self.client_user.domain_database_id.nil? || self.client_user.domain_database_id == DomainModel.active_domain[:domain_database_id]
        true
      end
    else
      role = role.to_s unless role.is_a?(Integer)
      return false if role == 'system_admin' || role == 'client_admin' || role == 'client_user'
      roles_list.include?(Role.expand_role(role,target))
    end
  end

  # Check if a user has the requested permission to access a piece of content
  # permission could be: 
  #   nil - return true
  #   a string or symbol - check has_role?
  #   a hash with :model - check ":permission"_granted? on the model and an optional base permission
  #   a hash with :target - check self.has_role? on the :permission and an optional base permission
  def has_content_permission?(permission)
    if !permission
      true
    elsif  permission.is_a?(Hash)
      if permission[:model]
        permission[:model].send("#{permission[:permission]}_granted?",self) && (!permission[:base] || self.has_role?(permission[:base]) )
      else
        self.has_role?(permission[:permission],permission[:target])  && (!permission[:base] || self.has_role?(permission[:base]) )
      end
    else
      self.has_role?(permission)
    end
  end

  # Returns a default anonymous user
  def self.default_user
    usr = self.new
    usr.user_class_id =  UserClass.anonymous_class_id
    return usr
  end


  # Returns a dingbat representing the user level
  def user_level_dingbat
    if self.user_level == 0
      "&#10061;"
    elsif self.acknowledged?
       "&##{10111 + self.user_level};"
    else
      "&##{10121 + self.user_level};"
    end
  end


  # Returns the full name of the user
  def name
    if !self.full_name.blank?
      self.full_name
    elsif self.client_user
      self.client_user.name
    elsif self.first_name || self.last_name
      [ self.first_name,self.middle_name,self.last_name].select { |elm| !elm.blank? }.join(" ")
    else
      'Anonymous'.t
    end
  end
  
  # Sets individual name components (first_name, middle_name, last_name) from a single string
  def name=(val)
    name = val.to_s.strip.split(" ")
    if name.length > 1
      self.last_name = name[-1]
      other_names = name[0..-2]
      self.first_name = other_names[0]
      self.middle_name = other_names[1..-1].join(" ") if other_names[1..-1]
    else
      self.first_name = name[0]
    end  
  end

  # Checks to see if user has a name
  def missing_name?
    self.full_name.blank? && self.first_name.blank? && self.last_name.blank? && self.client_user.nil?
  end

  # Sets and saves individual name
  def update_name(val, opts={})
    return unless self.missing_name?
    return if val == 'Anonymous'.t || val.blank?
    self.name = val
    self.save if self.id
  end

  # Returns an introduction string, either from
  # the attribute or based on gender
  def introduction
    intro = read_attribute(:introduction)
    if !intro.blank?
      intro
    elsif !self.gender.blank?
      self.gender == 'm' ? "Mr." : "Mrs."
    else 
      ''
    end
  end

  def triggered_attributes
    @triggered_attributes ||= self.attributes.merge(:name => self.name)
  end

  def before_update #:nodoc:
    self.get_handler_info(:end_user, :before_update).each do |handler|
      handler[:class].end_user_updated self
    end
  end

  def before_save #:nodoc:
    if self.password && !self.password.empty?
      self.salt = EndUser.generate_hash if self.salt.blank?
      self.hashed_password = EndUser.hash_password(self.password,self.salt) if self.password && !self.password.empty?
    end
    self.options ||= {}
    
    self.source = 'import' if self.source.blank?
    self.registered_at = Time.now if self.registered? && self.registered_at.blank?

    %w(first_name middle_name last_name suffix).each do |fld|
      self.send(fld).strip! unless self.send(fld).blank?
    end

    self.full_name = [ self.first_name, self.middle_name, self.last_name, self.suffix ].select { |elm| !elm.blank? }.join(" ")
    
    if self.gender.blank? && !self.introduction.blank?
      if self.introduction.downcase == 'mr.'
        self.gender = 'm'
      elsif self.introduction.downcase == 'mrs.' || self.introduction.downcase == 'ms.'
        self.gender = 'f'
      end
    end

    true
  end

  def self.fetch_user_level(end_user_id)
    end_user_id = end_user_id.to_i
    results = self.connection.execute "SELECT user_level FROM end_users WHERE id = #{self.connection.quote end_user_id}"
    results.each_hash { |row| return row['user_level'].to_i }
    nil
  end

  def elevate_user_level(level)
    self.class.elevate_user_level self.id, level
  end

  def self.elevate_user_level(end_user_id, user_level)
    return unless end_user_id

    end_user_id = end_user_id.to_i
    user_level = user_level.to_i
    level = self.fetch_user_level(end_user_id)
    if level && level < user_level
      self.connection.execute "UPDATE end_users SET acknowledged = 0, user_level = #{self.connection.quote user_level} WHERE id = #{self.connection.quote end_user_id} AND user_level < #{self.connection.quote user_level}"
      true
    else
      false
    end
  end

  def unsubscribe
    self.class.unsubscribe self.id
  end

  def self.unsubscribe(end_user_id)
    end_user_id = end_user_id.to_i
    if self.fetch_user_level(end_user_id) > 0
      self.connection.execute "UPDATE end_users SET acknowledged = 0, user_level = 0 WHERE id = #{self.connection.quote end_user_id} AND user_level > 0"
      true
    else
      false
    end
  end

  def update_user_value(val)
    self.class.update_user_value self.id, val
  end

  def self.update_user_value(end_user_id, val)
    end_user_id = end_user_id.to_i
    val = val.to_i
    self.connection.execute "UPDATE end_users SET `value` = `value` + #{self.connection.quote val} WHERE id = #{self.connection.quote end_user_id}"
  end

  def update_editor_login #:nodoc:
    if self.registered? && self.activated? && self.editor?
      editor_login= EditorLogin.find_by_domain_id_and_email(Configuration.domain_id,self.email) || EditorLogin.new
      editor_login.update_attributes(:domain_id => Configuration.domain_id,
                                     :login_hash => self.class.generate_hash,
                                     :email => self.email,
                                     :end_user_id => self.id,
                                     :hashed_password => self.hashed_password)
    end
  end
  
  alias_method :tag_names_original, :tag_names=
  
  # Finds a target given an email address or returns a new EndUser object
  # that is saved by default (doesn't push any additional attributes)
  #
  # Options
  # [:no_create]
  #   Do not create save the user if we don't have an existing record
  # [:user_class_id]
  #  Set the user class to the option specified, or use the default class
  def self.find_target(email,options = {})
    target = self.find_by_email(email)
    if !target
      target = EndUser.new(:email => email)
      target.user_class_id = options[:user_class_id] || UserClass.default_user_class_id
      target.source = options[:source] if options[:source]
      target.save unless options[:no_create]
    end
    target
  end


  def anonymous_tracking_information
    self.attributes.symbolize_keys.slice(:source_user_id,:referrer,:tag_names)

  end

  def anonymous_tracking_information=(val)
    self.attributes = val.symbolize_keys.slice(:source_user_id,:referrer,:tag_names)
  end

  
=begin rdoc
This is the easiest way to create an EndUser, for example:

        @user = EndUser.push_target('example@domain.com', :name => 'Svend Karlson')

This will return either an existing user with the specified email address or a newly-saved
user object. 

Addresses are stored separately in the EndUserAddress model, but push_target can pass through
phone, fax, address, address_2, city, state, zip and country.

The :no_register option will not return a user object if the found target is already registered.

WARNING: push_target does not sanitize any inputs, so in theory all attributes can be modified,
so be careful when allowing user submitted arguments in.

Use the Hash#slice method to only select the fields you actually want to let in, for example:

     @user = EndUser.push_target(params[:user][:email],params[:user].slice(:first_name,:last_name))

Not doing so could allow a user to change their user profile (for example) and elevate their permissions.

=end
  def self.push_target(email,options = {},tracking_options = {})
    opts = options.clone
    opts.symbolize_keys!

    user_class_id = opts.delete(:user_class_id) || UserClass.default_user_class_id
    target = self.find_target(email, :user_class_id => user_class_id, :no_create => true, :source => opts.delete(:source))

    target.anonymous_tracking_information = tracking_options

    # Don't mess with registered users if no_register is set    
    no_register = opts.delete(:no_register)
    return if no_register && target.registered?

    address_fields = %w(phone fax address address_2 city state zip country)
    adr_values = {}
    address_fields.each do |fld|
      val = opts.delete(fld.to_sym)
      if !val.blank?
        adr_values[fld.to_sym] = val
      end
    end 
    
    adr = nil
    if adr_values.keys.length > 0
      adr = target.address || target.build_address
      adr.attributes = adr_values
      adr.end_user_id  = target.id
      adr.save
      target.address_id = adr
    end
    
    target.attributes = opts
    target.user_class_id = user_class_id if target.user_class_id.blank?
    target.save
    
    # Need to get an id for the target to save after the fact
    adr.update_attribute(:end_user_id,target.id) unless !adr || adr.end_user_id
    
    target
  end

  def reload
    @tag_name_cache = nil if self.id
    super
  end

  # Return a clone of the current address or work address object 
  def default_address
    adr = (self.address &&  !self.address.address.blank?) ? self.address : ( (self.work_address && !self.work_address.blank? ) ? self.work_address : EndUserAddress.new() )
    adr.first_name = self.first_name
    adr.last_name = self.last_name
    adr.end_user_id = self.id
    adr.clone
  end
  
  # Return the current shipping address or the current address if no shipping adr
  def current_shipping_address
    if self.shipping_address && !self.shipping_address.address.blank?
     self.shipping_address
    elsif self.billing_address && !self.billing_address.address.blank?
      self.billing_address
    else
      self.default_address
    end
  end

  # Return the current billing address
  def current_billing_address
    if self.billing_address && !self.billing_address.address.blank?
     self.billing_address
    else
      self.default_address
    end
  end
  
  # Returns a list of existing tags
  def self.tag_options
    Tag.select_options
  end

  # Returns a tag cloud
  def self.tag_cloud(sizes=[])
    Tag.get_tag_cloud
  end

  def clear_tags! #:nodoc:
    self.end_user_tags.delete_all
  end

  def tags_array
    if @tag_name_cache.is_a?(Array)
      @tag_name_cache
    else
      self.tags.collect(&:name)
    end
  end

  # Immediately tag this user with the listed tags, saving them to the tag cache
  # if the user hasn't been saved yet
  def tag(tags_list, options={})
    if self.id
      tags_list = tags_list.join(",") if tags_list.is_a?(Array)
      self.add_tags(tags_list)
    else
      @tag_name_cache ||= []
      tags_list = self.tag_name_helper(tags_list) unless tags_list.is_a?(Array)
      @tag_name_cache = @tag_name_cache + tags_list
    end
  end

  # Immediately remove the listed tags from the user
  def tag_remove(tags, options = {})
    self.remove_tags(tags)
  end

  def tag_names_add(tag_list,options={})  #:nodoc:
    self.tag(tag_list)
  end 

  def tag_cache_tmp
    @tag_name_cache
  end

  def tag_cache_after_save #:nodoc:
    if @tag_name_cache.is_a?(Array)
      @tag_name_cache.uniq!
      tags = self.end_user_tags
        
      @existing_tags = []
      tags.each do |tg|
        if tg.tag && @tag_name_cache.include?(tg.tag.name)
          @existing_tags << tg.tag.name
        else
          tg.destroy
          tg.tag.destroy if(tg.tag && tg.tag.end_user_tags.size == 0)
        end
      end
        
      @tag_name_cache.each do |tag_name|
        unless @existing_tags.include?(tag_name)
          tg = Tag.get_tag(tag_name)
          # Be explicit about the content_type for Content models (which don't have a real class name)
          self.end_user_tags.create(:tag_id => tg.id)
        end
      end
    end
      
    @tag_name_cache = nil
  end

  # Validates a users registration given a list of required fields
  def validate_registration(opts = {})
    fields = %w(gender first_name last_name dob username)
    fields.each do |fld|
      fld = fld.to_sym
      if opts[fld] == 'required'
         errors.add(fld,'is missing') if self.send(fld).to_s.empty?
      end 
    end
  
  end
  
  # Return a hashed password given an optional salt
  def self.hash_password(pw,salt=nil) 
    if !salt.blank?
      Digest::SHA1.hexdigest(salt.to_s + pw)
    else
      Digest::SHA1.hexdigest(pw)
    end
  end

  # Generate and assign a random activation_string
  def generate_activation_string
    self.activation_string =  self.class.generate_hash[0..48]
  end
  
  # Generate a random password
  def self.generate_password
    self.generate_vip
  end

  # Generate a random VIP string
  def self.generate_vip 
     letters = '123456789ACEFGHKMNPQRSTWXYZ'.split('')
     unique = false
     sec = Time.now.sec
     while(!unique)
      num = (0..7).to_a.collect { |n| letters[(rand(20000) + sec) % letters.length] }.join
      unique = true unless EndUser.find_by_vip_number(num)
     end
     num
  end
  
  # Return an HTML-formatted description of this user
  def html_description
   output = '<table>'
   %w(email first_name last_name vip_number).each do |fld| 
     output += "<tr><td>#{fld.humanize.t}:</td><td>#{self.send(fld)}</td></tr>"
   end
   [['Work Address',self.work_address], ['Address',self.address] ].each do |adr|
     if adr[1]    
       output += "<tr><th colspan='2'>#{"Work Address".t}</th></tr>"
       %w(company phone address city state zip country).each do |fld|
          unless adr[1].send(fld).blank?
           output += "<tr><td>#{fld.humanize.t}:</td><td>#{adr[1].send(fld)}</td></tr>"
          end
       end
     end
   end
   output << '</table>'
   output
  end
  
  # Return a text-formatted description of the user
  def text_description
   output = ''
   %w(email first_name last_name vip_number).each do |fld| 
     output << "#{fld.humanize.t}:#{self.send(fld)}\n"
   end
   [['Work Address',self.work_address], ['Address',self.address] ].each do |adr|
     if adr[1]    
       output += "\n#{adr[0].t}:\n"
       %w(company phone address city state zip country).each do |fld|
          unless adr[1].send(fld).blank?
           output += "#{fld.humanize.t}:#{adr[1].send(fld)}\n"
          end
       end
     end
   end
   output << "\n"
   output
  end
    
  
  def gallery_can_upload(usr) #:nodoc:
    usr.id == self.id; end
  def gallery_can_edit(usr) #:nodoc:
    usr.id == self.id; end    
  def is_admin?(usr); #:nodoc:
    usr.id == self.id; end

  def run_update_profile_photo(args)
    url = args[:url]

    return unless DomainFile.available_file_storage > 0

    uri = nil
    begin
      uri = URI.parse(url)
    rescue URI::InvalidURIError => e
      logger.error e
      return
    end

    photo = DomainFile.create :filename => uri, :parent_id => Configuration.options.user_image_folder

    if photo.id
      self.domain_file_id = photo.id
      self.admin_edit = true if self.email.blank?
      self.save
    end
  end

  def last_log_entry
    @last_log_entry ||= (DomainLogEntry.find(:first, :conditions => {:user_id => self.id}, :order => 'occurred_at DESC') || DomainLogEntry.new)
  end

  def last_session
    self.last_log_entry.domain_log_session
  end

  def referral
    @referral
  end

  def referral=(ref)
    ref = ref.to_s.strip
    return if ref.blank?
    @referral = ref
    self.source_user = EndUser.find_by_membership_id @referral
    self.source_user ||= EndUser.find_by_username @referral
    self.source_user ||= EndUser.find_by_email @referral
    self.source = 'referral' if self.source_user
  end
end
