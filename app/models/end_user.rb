# Copyright (C) 2009 Pascal Rettig.

require 'digest/sha1'

# User Levels:
# 0 - Opt-Out
# 1 - Manually Added
# 2 - Visited
# 3 - Registered
# 4 - Subscribed
# 5 - Conversion


# Sources:
# website
# import
# referrel

class EndUser < DomainModel
  validates_confirmation_of :password

  # Only need an email if we aren't a client user
  validates_presence_of :email, :if => Proc.new { |usr| !usr.client_user_id && !usr.admin_edit }

  validates_format_of :username, :with => /^([a-zA-Z0-9!#\$%^&*@()_\-.]+)$/,:allow_blank => true, 
                      :message => 'can only contain numbers, letters, and the symbols: !@#$%^&()-_.'

  # Email always needs to be unique - but can be blank if user is an client user
  validates_uniqueness_of :email,:allow_blank => true
  validates_uniqueness_of :username, :allow_blank => true
  validates_presence_of :user_class
  validates_as_email :email
  
  attr_accessor :admin_edit
  attr_accessor :password
  attr_accessor :site_policy

  attr_reader :login
  
  belongs_to :domain_file
  belongs_to :second_image, :class_name => 'DomainFile',:foreign_key => :second_image_id
  
  belongs_to :address, :class_name => 'EndUserAddress', :foreign_key => :address_id
  belongs_to :shipping_address, :class_name => 'EndUserAddress', :foreign_key => :shipping_address_id
  belongs_to :billing_address, :class_name => 'EndUserAddress', :foreign_key => :billing_address_id
  belongs_to :work_address, :class_name => 'EndUserAddress', :foreign_key => :work_address_id
  has_many :addresses, :class_name => 'EndUserAddress', :dependent => :destroy

  has_one :tag_cache, :dependent => :destroy
  
  has_many :end_user_cookies, :dependent => :delete_all, :class_name => 'EndUserCookie'

  has_many :email_friends, :dependent => :delete_all
  has_many :end_user_actions, :dependent => :delete_all

  has_many :end_user_tokens, :dependent => :delete_all, :include => [ :access_token ]

  has_many :access_tokens, :through => :end_user_tokens
  
  acts_as_taggable :join_table => 'end_user_tags', :join_class_name => 'EndUserTag'

  has_many :end_user_tags, :class_name => 'EndUserTag'
  #has_many :tags, :through => :user_tags
  
  belongs_to :source_user, :class_name => 'EndUser'
  
  has_many :user_subscriptions, :through => :user_subscription_entries
  has_many :user_subscription_entries, :dependent => :destroy
  
  has_many :domain_emails

  belongs_to :user_class

  attr_protected :client_user_id
  attr_accessor :email_confirmation

  accepts_nested_attributes_for :end_user_tokens

  has_options :introduction, ['Mr.','Mrs.','Ms.']
  
  has_options :user_level, [ [ '0 - Opt-Out', 0 ], 
                        [ '1 - Added Manually', 1],
                        [ '2 - Visited', 2],
                        [ '3 - Registered', 3],
                        [ '4 - Subscribed', 4],
                        [ '5 - Converison', 5] ]
                      
  has_options :source, [ [ 'Website', 'website' ],
                         [ 'Import', 'import' ],
                         [ 'Referrel', 'referrel' ] ]



  ## Validation Fucntions 
  
  
  
  def before_validation
    self.email = self.email.downcase unless self.email.blank?
  end

  def validate
    if self.registered? && !self.hashed_password && (!self.password || self.password.empty?)
      errors.add(:password, 'is missing')
    end  
  end

  def validate_password(pw)
    return EndUser.hash_password(pw) == self.hashed_password
  end

  def update_verification_string!
    self.update_attribute(:verification_string, Digest::SHA1.hexdigest(Time.now.to_s + rand(1000000000000).to_s)[0..12])
  end

  
  def client_user?
    client_user_id.to_i > 0
  end

  def client_user
    return nil unless client_user_id
    return @client_user if @client_user
    @client_user = ClientUser.find_by_id(client_user_id)
  end

  # Return an Array of subscription ids
  def subscriptions
      self.user_subscriptions.collect { |sub| sub.id }
  end


  ## Access Token Stuff
  def tokens
    through_connection_cache(:end_user_tokens,@access_token_cache)
  end

  def tokens=(val)
    @access_token_cache = val
  end

  after_save :token_cache_update

  def token_cache_update
    if(@access_token_cache)
      set_through_collection_with_attributes(:end_user_tokens,:access_token_id,@access_token_cache)
    end
  end

  def add_token!(tkn,options = { })
    eut = self.end_user_tokens.find_by_access_token_id(tkn) ||
      self.end_user_tokens.create(:access_token_id => tkn.id)

    # If we are setting any additional options,
    # then override the existing endusertoken
    if options.has_key?(:valid_until) || options.has_key?(:target) || options.has_key?(:valid_at)
      eut.update_attributes(options.slice(:valid_until,:target,:valid_at))
    end
  end
  
  def self.select_options(editor=false)
    self.find(:all, :order => 'last_name, first_name',:include => :user_class,
              :conditions => [ 'user_classes.editor = ?',editor ] ).collect { |usr| [ "#{usr.last_name}, #{usr.first_name} (##{usr.id})", usr.id ] } 
  end
  
  
  def image
    self.domain_file ? self.domain_file : Configuration.missing_image(self.gender)
  end
  
  
  def identifier_name
    self.name + " (#{self.id})"
  end
  
  
  def editor?
    self.user_profile.editor?
  end
  
  serialize :options
  
  include VerifiedModel
  
  # Get user class, otherwise just the first (anonymous) user class
  def user_profile
    self.user_class || UserClass.anonymous_class
  end

  def user_profile_id
    self.user_class_id || UserClass.anonymous_class_id
  end


  ## Action Functionality
  def action(action_path,opts = {})
    opts[:level] ||= 3
    EndUserAction.log_action(self,action_path,opts)
  end

  def custom_action(action_name,descriptions, opts = {})
    EndUserAction.log_custom_action(self,action_name,opts)
  end
  ## Login Functions
  
  def self.login_by_email(email,password)
    usr = find(:first,:conditions => ["email != '' AND email = ? AND activated = 1 AND registered = 1",email.to_s.downcase] )
    
    hashed_password = EndUser.hash_password(password || "",usr.salt) if usr
    if usr && usr.hashed_password == hashed_password
        usr
    else
      nil
    end
  end  
  
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
  
  
  def self.find_visited_target(email)
    EndUser.find_by_email(email) || EndUser.create( :email => email,
                                                    :user_level => 2,
                                                    :source => 'website',
                                                    :registered => false )
  end
  
  def update_domain_emails
    self.domain_emails.each { |email| email.save }
  end

  def roles_list
    return @roles_list if @roles_list

    @roles_list = self.user_profile.cached_role_ids
    @roles_list += self.end_user_tokens.active.inject([]) do |arr,elm| 
      if elm.target_type.blank?
        arr += elm.access_token.cached_role_ids
      elsif elm.target
        if elm.target.token_valid?
          arr += elm.access_token.cached_role_ids
        end
      end
    end
    
    @roles_list
  end
  
  
  def has_any_role?(expanded_roles)
    # Client users have all roles
    if(self.client_user_id && self.user_class_id == UserClass.client_user_class_id)
      true
    else
      permitted = false
      roles_list.each do |role|
        if expanded_roles.include?(role)
          permitted = true
          break
        end
      end

      permitted
    end
  end

  def has_role?(role,target=nil)
    if(self.client_user_id && self.user_class_id == UserClass.client_user_class_id)
      true
    else
      roles_list.include?(Role.expand_role(role,target))
    end
  end
  
  def self.default_user
    usr = self.new
    return usr
  end

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
  
  def name=(val)
    name = val.to_s.strip.split(" ")
    if name.length > 1
      self.last_name = name[-1]
      other_names = name[0..-2]
      self.first_name = other_names[0]
      self.middle_name = other_names[1..-1].join(" ") if other_names[1..-1]
    else
      self.first_name = ''
      self.last_name = name[0]
    end  
  end
  
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
  
  def before_save
    
    if self.password && !self.password.empty?
      self.salt = EndUser.generate_hash if self.salt.blank?
      self.hashed_password = EndUser.hash_password(self.password,self.salt) if self.password && !self.password.empty?
    end
    self.options ||= {}
    
    if self.user_level < 3 && self.registered?
      self.user_level = 3
    end
    
    self.source = 'import' if self.source.blank?
    self.registered_at = Time.now if self.registered? && self.registered_at.blank?
    
    self.full_name = [ self.first_name, self.middle_name, self.last_name, self.suffix ].select { |elm| !elm.blank? }.join(" ")
    
    if self.gender.blank? && !self.introduction.blank?
      if self.introduction.downcase == 'mr.'
        self.gender = 'm'
      elsif self.introduction.downcase == 'mrs.' || self.introduction.downcase == 'ms.'
        self.gender = 'f'
      end
    end
  end
  
  def update_editor_login
    if self.editor?
      editor_login= EditorLogin.find_by_domain_id_and_email(Configuration.domain_id,self.email) || EditorLogin.new
      editor_login.update_attributes(:domain_id => Configuration.domain_id,
                                     :email => self.email,
                                     :end_user_id => self.id,
                                     :hashed_password => self.hashed_password)
    end
  end
  
  alias_method :tag_names_original, :tag_names=
  
  
  def self.find_target(email,options = {})
    target = self.find_by_email(email)
    if !target && !options[:no_create]
      target = EndUser.create(:email => email,:user_class_id => options[:user_class_id] || UserClass.default_user_class_id)
    elsif !target
      target = EndUser.new(:email => email,:user_class_id => options[:user_class_id] || UserClass.default_user_class_id)
    end
    target
  end
  
  def self.push_target(email,options = {})
    target = self.find_target(email,:no_create => true)
    opts = options.clone
    opts.symbolize_keys!

    # Don't mess with registered users if no_register is set    
    no_register = opts.delete(:no_register)
    return if no_register && target.registered?
    
  
    address_fields = %w(phone fax address address_2 city state zip country)
    adr_values = {}
    address_fields.each do |fld|
      val = opts.delete(fld.to_sym)
      if val
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
    target.save
    
    # Need to get an id for the target to save after the fact
    adr.update_attribute(:end_user_id,target.id) unless !adr || adr.end_user_id
    
    target
  end
  
  
  ## Tag Functionality - TODO: Rewrite Needed
  
  attr_reader :tag_cache
  
  # Model issue 
  def clear_tags!
    connection.execute("DELETE FROM end_user_tags WHERE end_user_id=" + quote_value(self.id))
  end

  def tag(tags_list, options = {})
     if !self.id
      if !@tag_cache.to_s.blank?
        @tag_cache = @tag_cache.split(",")
      else
        @tag_cache = []
      end
      @tag_cache << tags_list.to_s unless tags_list.blank?      
      @tag_cache = @tag_cache.join(",")
      return 
    end
    super
    update_tag_cache(self.tag_names(true).join(","))

  end

  def tag_remove(tags, options = {})
    super
    update_tag_cache(self.tag_names(true).join(","))
  end

  def update_tag_cache(names)
    (self.tag_cache || self.build_tag_cache).update_attribute(:tags,names)
  end

  def tag_names_add(tag_list,options={})
    self.tag(tag_list,options.merge({:separator => ',', :clear => false}))
  end 
  
  def tag_names=(tags,options={})
    self.tag_names_original(tags,options.merge({:separator => ',', :clear => true}))
  end

  def tag_cache_tags
    if self.attributes.has_key?('tag_cache_tags')
      self.attributes['tag_cache_tags']
    else
     (self.tag_cache ? self.tag_cache.tags : '')
    end
  end

  def self.find_tagged_with(options = {}) 
          options = { :separator => ' ' }.merge(options)
          
          tag_names = Taggable::Acts::AsTaggable.split_tag_names(options[:any] || options[:all], options[:separator], normalizer)
          raise "No tags were passed to :any or :all options" if tag_names.empty?

          o, o_pk, o_fk, t, tn, t_pk, t_fk, jt = set_locals_for_sql
          sql = "SELECT #{o}.*, tag_cache.tags as tag_cache_tags FROM (#{jt}, #{o}, #{t}) LEFT JOIN tag_cache ON ( #{o}.#{o_pk} = tag_cache.end_user_id ) WHERE #{jt}.#{t_fk} = #{t}.#{t_pk} 
                AND #{o}.#{o_pk} = #{jt}.#{o_fk}"
          sql << " AND  ("
          sql << tag_names.collect {|tag| sanitize_sql( ["#{t}.#{tn} = ?",tag])}.join(" OR ")
          sql << ")"
          sql << " AND #{sanitize_sql(options[:conditions])}" if options[:conditions]
          if postgresql?
            sql << " GROUP BY #{model_columns_for_sql}"
          else
            sql << " GROUP BY #{o}.#{o_pk}"
          end
          sql << " HAVING COUNT(#{o}.#{o_pk}) = #{tag_names.length}" if options[:all]              
          sql << " ORDER BY #{options[:order]} " if options[:order]
          add_limit!(sql, options)
          
          find_by_sql(sql)
  end

  def self.count_tagged_with(options = {}) 
          options = { :separator => ' ' }.merge(options)
          
          tag_names = Taggable::Acts::AsTaggable.split_tag_names(options[:any] || options[:all], options[:separator], normalizer)
          raise "No tags were passed to :any or :all options" if tag_names.empty?

          o, o_pk, o_fk, t, tn, t_pk, t_fk, jt = set_locals_for_sql
          sql = "SELECT COUNT(DISTINCT #{o}.id) as cnt FROM (#{jt}, #{o}, #{t})  WHERE #{jt}.#{t_fk} = #{t}.#{t_pk} 
                AND #{o}.#{o_pk} = #{jt}.#{o_fk}"
          sql << " AND  ("
          sql << tag_names.collect {|tag| sanitize_sql( ["#{t}.#{tn} = ?",tag])}.join(" OR ")
          sql << ")"
          sql << " AND #{sanitize_sql(options[:conditions])}" if options[:conditions]
          if options[:all]
            sql << " GROUP BY  #{o}.#{o_pk}"
            sql << " HAVING COUNT(#{o}.#{o_pk}) = #{tag_names.length}"               
            sql = 'SELECT COUNT(*) FROM (' + sql + ') as counter'
          end
          count_by_sql(sql)
  end  
  
  def self.find_not_tagged_with(options = {})
    options = { :separator => ',' }.merge(options)

    tag_names = Taggable::Acts::AsTaggable.split_tag_names(options[:any] || options[:all], options[:separator], normalizer)
    
    

    o, o_pk, o_fk, t, tn, t_pk, t_fk, jt = set_locals_for_sql
    sql = "SELECT #{o}.*, tag_cache.tags as tag_cache_tags FROM #{o} LEFT JOIN tag_cache ON ( #{o}.#{o_pk} = tag_cache.end_user_id ) LEFT JOIN #{jt} ON (  #{o}.#{o_pk} = #{jt}.#{o_fk} ) LEFT JOIN  #{t} ON ( #{jt}.#{t_fk} = #{t}.#{t_pk}
	  "
	  
    sql << " AND  ("
    sql << tag_names.collect {|tag| sanitize_sql( ["#{t}.#{tn} = ?",tag])}.join(" OR ")
    sql << ") )"
    sql << " WHERE #{sanitize_sql(options[:conditions])}" if options[:conditions]
    if postgresql?
      sql << " GROUP BY #{model_columns_for_sql}"
    else
      sql << " GROUP BY #{o}.#{o_pk}"
    end
    if options[:any]
      sql << " HAVING COUNT(#{t}.id) = 0 "
    else
      sql << " HAVING COUNT(#{t}.id) <  " + tag_names.length.to_s
    end
    sql << " ORDER BY #{options[:order]} " if options[:order]
    add_limit!(sql, options)

    find_by_sql(sql)
  end

  def self.count_not_tagged_with(options = {})
    options = { :separator => ',' }.merge(options)

    tag_names = Taggable::Acts::AsTaggable.split_tag_names(options[:any] || options[:all], options[:separator], normalizer)
    
    

    o, o_pk, o_fk, t, tn, t_pk, t_fk, jt = set_locals_for_sql
    sql = "SELECT COUNT(DISTINCT #{o}.id) FROM #{o}  LEFT JOIN #{jt} ON (  #{o}.#{o_pk} = #{jt}.#{o_fk} ) LEFT JOIN  #{t} ON ( #{jt}.#{t_fk} = #{t}.#{t_pk}
	  "
	  
    sql << " AND  ("
    sql << tag_names.collect {|tag| sanitize_sql( ["#{t}.#{tn} = ?",tag])}.join(" OR ")
    sql << ") )"
    sql << " WHERE #{sanitize_sql(options[:conditions])}" if options[:conditions]
    if postgresql?
      sql << " GROUP BY #{model_columns_for_sql}"
    else
      sql << " GROUP BY #{o}.#{o_pk}"
    end
    if options[:any]
      sql << " HAVING COUNT(#{t}.id) = 0 "
    else
      sql << " HAVING COUNT(#{t}.id) <  " + tag_names.length.to_s
    end

    sql = 'SELECT COUNT(*) FROM (' + sql + ') as counter'

    count_by_sql(sql)
  end
  
  

  def validate_registration(opts = {})
    fields = %w(gender first_name last_name dob username)
    fields.each do |fld|
      fld = fld.to_sym
      if opts[fld] == 'required'
         errors.add(fld,'is missing') if self.send(fld).to_s.empty?
      end 
    end
  
  end

  def self.import_fields
    
    fields = [ [ 'email', 'Email'.t, ['email','e-mail' ], :field ],
      [ 'language', 'Language'.t, ['language' ], :field ],
      [ 'gender', 'Gender'.t, [ 'gender','sex' ], :special ],
      [ 'tags', 'Add Tags'.t, [ 'tags' ], :tags ],
      [ 'first_name', 'First Name'.t, ['first name'], :field ],
      [ 'last_name', 'Last Name'.t, ['last name'], :field ],
      [ 'name', 'Full Name'.t, ['name'], :special ],
      [ 'password', 'Password'.t, ['password'], :special ],
      [ 'remove_tags', 'Remove Tags'.t, [ 'tags' ], :tags ],
#      [ 'domain_file_id', 'Image'.t, :special ],
      ['dob', 'Date of Birth'.t, ['date of birth','birth date'], :special ],
      ['vip_number', 'VIP Number'.t, ['vip number','vip'], :field ],
    ].collect do |fld|
      [ fld[0], fld[1], fld[2] + fld[2].collect { |nm| nm.t }, fld[3] ]
    end
    
    # Add in address fields
    %w(work home billing).each do |address|
      adr_text = address.humanize
      %w(company phone fax address city state zip country).each do |field|
        if address == 'work' || field != 'company'
          human_field = adr_text + ' - ' + field.humanize
          fields << [ address + "_" + field, human_field.t, [ human_field.downcase, human_field.downcase.t ], :address ]
	end
      end
    end
    
    fields
  end 
  
  def self.import_csv(filename,data,options={})
    actions = data[:actions]
    matches = data[:matches]
    create = data[:create]

    deliminator = options[:deliminator]
    
    
    opts = options[:options]
    user_opts = opts[:user_options] || {}
    
    page = options[:page].to_i
    page_size = options[:page_size] || 50
    
    import = options[:import] || false
    
    page = 1 if page < 1
    
    unless import
      reader_offset = (page-1) * page_size
      reader_limit = reader_offset + page_size
    end
    
    entry_errors = []
    
    invert_matches = matches.invert
    email_field = nil
    reader = CSV.open(filename,"r",deliminator)
    file_fields = reader.shift
    fields = []
    
    user_fields = EndUser.import_fields
    
    file_fields.each_with_index do |fld,idx|
      if actions[idx.to_s] == 'm'
        match = user_fields.detect do |user_fld|
          user_fld[0] == matches[idx.to_s]
        end
        if match
          fields << [match[1],idx,'match',match[0],match[3]]
          if match[0] == 'email'
            email_field = idx
          end
	end
      end
    end
    
    parsed_data = []
    idx = 0
    
    opts[:all_tags] ||= ''
    opts[:create_tags] ||= ''
    
    new_user_class = UserClass.find_by_id(opts[:user_class_id]) || UserClass.default_user_class
    reader.each do |row|

      if(row.join.blank?)
        idx+=1
        next
      end
      
      entry_errors = []
      if !reader_offset || idx >= reader_offset
	entry = EndUser.find_by_email(row[email_field]) unless row[email_field].blank?
	
	if import
	 entry_addresses = {}
	 
	 entry_values = {}
	 entry_method = :update
	 unless entry
	   entry_method = :new
	   entry = EndUser.new(:user_class_id => new_user_class.id, :source => 'import')
	 end

	 
	 extra_tags = nil
	 remove_tags = nil
	 
	 if opts[:import_mode] == 'normal' ||
	    ( entry_method == :update  && opts[:import_mode] == 'update' ) ||
	    ( entry_method == :create && opts[:import_mode] == 'create' )
	  fields.each do |fld|
	      value = row[fld[1]].to_s
	      if fld[4].to_sym == :field
		entry_values[fld[3]] = value
	      elsif fld[4].to_sym == :address
		process_import_address(entry,entry_addresses,fld[3],value)
	      elsif fld[4].to_sym == :tags
	        extra_tags = value
	      elsif fld[4].to_sym == :remove_tags
	         remove_tags = value
	      else
		process_import_field(entry,fld[3],value)
	      end
	    end
	    
	    entry.attributes = entry_values
	    entry.valid?

            if true # skip validation, allow no email address
	      entry_addresses.each do |key,adr|
		adr.save
		entry.send("#{key}=".to_sym,adr.id)
	      end

              if user_opts.include?('vip') &&  entry.vip_number.blank?
                entry.vip_number = EndUser.generate_vip()
              end

	      
	      if(entry.save(false))
		entry_addresses.each do |key,adr|
		  if adr.end_user_id != entry.id 
		    adr.update_attribute(:end_user_id,entry.id)
		  end
		end
		# add
		
		
		if !opts[:all_tags].empty?
		  entry.tag_names_add(opts[:all_tags])
		end
		# Add any create tags
		if !opts[:create_tags].empty? && entry_method == :new
		  entry.tag_names_add(opts[:create_tags])
		end

		if extra_tags
		  entry.tag_names_add(extra_tags)
		end
		
		if remove_tags
		  entry.tag_remove(remove_tags, :separator => ',')
		end

	      end
	    else
	     entry_errors << [idx, entry.errors ]
	    end
	  end
	else
	  act = entry ? 'm' : 'c'
	  act = 's' if act == 'm' && opts[:import_mode] == 'create'
	  act = 's' if act == 'c' && opts[:import_mode] == 'update'
	  
	  parsed_data << [ act ] + fields.collect do |fld|
	    row[fld[1]].to_s
	  end
	end
	
	if block_given?
	 yield 1,entry_errors
	end
      end
      
      # Exit if we are already over sample limit
      if reader_limit &&  idx >= reader_limit
        break;
      end
      idx+=1
    end
    reader.close
    
    if import
      return entry_errors
    else
      return fields, parsed_data
    end
  
  end
  
  def export_csv(writer,options = {})
    fields = [ ['email', 'Email'.t ],
               ['first_name', 'First name'.t ],
               ['last_name', 'Last name'.t ],
               ['language', 'Language'.t ],
               ['dob', 'Date of Birth'.t ],
               ['gender', 'Gender'.t ],
               ['user_level', 'User Level'.t ],
               ['source', 'Source'.t ]
              ]
    opts = options.delete(:include) ||  []
    if opts.include?('vip')
      fields << [ 'vip_number', 'VIP Number'.t ]
    end
    if opts.include?('tags')
      fields << ['tag_cache_tags', 'Tags'.t ]
    end
    
    
    address_objs = [ 'address', 'billing_address', 'work_address' ]
    
    %w(home billing work).each_with_index do |address,idx|
      if opts.include?(address)
        adr_obj = self.send(address_objs[idx])
	adr_text = address.humanize
	%w(company phone fax address city state zip country).each do |field|
	  if address == 'work' || field != 'company'
	    fields << [ nil, (adr_text + ' - ' + field.humanize).t, adr_obj ? adr_obj.send(field) : nil ]
	  end
	end
      end
    end    
    
    if options[:header]
      writer << fields.collect do |fld|
        fld[1]
      end
    end
    writer << fields.collect do |fld|
      if fld[0]
        self.send(fld[0])
      else
        fld[2]
      end
    end
  end
  
  def self.hash_password(pw,salt=nil) 
    if !salt.blank?
      Digest::SHA1.hexdigest(salt.to_s + pw)
    else
      Digest::SHA1.hexdigest(pw)
    end
  end

  def generate_activation_string
    self.activation_string =  self.class.generate_hash[0..48]
  end
  
  def self.generate_password
    self.generate_vip
  end

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
    
  
  def gallery_can_upload(usr); usr.id == self.id; end
  def gallery_can_edit(usr); usr.id == self.id; end    
  def is_admin?(usr); usr.id == self.id; end
  
  private
  
  def self.process_import_field(entry,field,value)
    case field
    when 'gender':
      if ['m','male','m'.t,'male'.t].include?(value.to_s.downcase)
        entry.gender = 'm'
      elsif ['f','female','f'.t,'female'.t].include?(value.to_s.downcase)
        entry.gender = 'f'
      end
    when 'password':
      entry.password = value
      entry.password_confirmation = value
      entry.registered = true
    when 'name':
      name = value.split(" ")
      if name.length > 1
        entry.last_name = name[-1]
        entry.first_name = name[0..-2].join(" ")
      else
        entry.first_name = ''
        entry.last_name = name[0]
      end
    when 'dob':
      entry.dob = value
    end
  end
  
  def self.process_import_address(entry,entry_addresses,field,value)
    address,field = field.split("_")
    adr = case address
      when 'work':
	entry_addresses['work_address_id'] ||= entry.work_address || EndUserAddress.new(:address_name => 'Default Work Address'.t )
      when 'home':
	entry_addresses['address_id'] ||= entry.address || EndUserAddress.new(:address_name => 'Default Address'.t )
      when 'billing':
        entry_addresses['billing_address_id'] ||= entry.billing_address || EndUserAddress.new(:address_name => 'Default Billing Address'.t )
    end
    
    adr.send("#{field}=".to_sym,value)
  end


  

end
