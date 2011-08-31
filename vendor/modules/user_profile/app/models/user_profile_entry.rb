# Copyright (C) 2010 Cykod LLC

class UserProfileEntry < DomainModel 
  before_save :add_url

  belongs_to :content_model
  belongs_to :user_profile_type
  belongs_to :end_user

  has_many :user_profile_view_entries

  named_scope :by_type, lambda { |type_id| 
    { :conditions => { :user_profile_type_id => type_id } }
  }

  named_scope :by_user, lambda { |user_id|
   { :conditions => { :end_user_id => user_id },
     :include => :end_user,
     :group => :end_user_id
   }
  }

  cached_content  :identifier => :url

  content_node(:container_type => 'UserProfileType', :container_field => 'user_profile_type_id', :push_value => true, :except => Proc.new() { |e| e.url.blank? }, :published => :published)

  def self.find_published_profile(url,profile_type_id)
    self.find_by_url_and_user_profile_type_id(url,profile_type_id,:conditions => { :published => true })
  end

  def self.fetch_entries(user_ids,profile_type_id=nil)
    if profile_type_id
      UserProfileEntry.by_type(profile_type_id).by_user(user_ids).all
    else
       UserProfileEntry.by_user(user_ids).all
    end

  end

  def content_node_body(language)
    body = self.attributes.values.map { |atr| [1] } + self.end_user.attributes.slice(*@@user_fields).values
    if self.content_model_entry
      body += self.content_model_entry.attributes.values
    end
    body += self.end_user.address.attributes.values if self.end_user.address
    body.select { |itm| itm.is_a?(String) }.join(" ")
  end

  def self.fetch_first_entry(user,profile_type_id=nil)
    if profile_type_id == nil
      type_ids = UserProfileType.match_classes(user.user_class_id) 
      profile_type = UserProfileType.find_by_id(type_ids[0])
      profile_type_id = profile_type.id if profile_type
    end
    profile_type_id ? self.fetch_entry(user.id,profile_type_id) : nil
  end

  @@user_fields =  %w(name image full_name first_name last_name gender dob source address billing_address work_address shipping_address salutation middle_name lead_source username cell_phone introduction suffix second_image username)

  def self.fetch_entry(user_id,profile_type_id)
    attr= { :user_profile_type_id => profile_type_id, :end_user_id => user_id } 
    entry = UserProfileEntry.find(:first, :conditions => attr) 
    if entry.nil? && profile_type = UserProfileType.find_by_id(profile_type_id)
      entry = UserProfileEntry.create(attr.merge(:content_model_id => profile_type.content_model_id)) 
    end
    entry
  end
  
 @@user_fields.each do |fld|
    class_eval <<-METHOD
      def #{fld}; self.end_user.#{fld}; end
    METHOD
  end

  def add_url
    self.url = create_url
  end

  def content_model_entry
    return @content_model_entry if @content_model_entry
    return nil unless self.content_model

    cls = self.content_model.model_class
    model_attributes = { self.user_profile_type.content_model_field_name => self.end_user_id }

    @content_model_entry = cls.find(:first,:conditions => model_attributes)
    unless @content_model_entry
      @content_model_entry = cls.new(model_attributes)
    end

    @content_model_entry
  end

  def content_model_entry_cache=(val)
    @content_model_entry = val
  end

  def create_full_name
    self.end_user.full_name if self.end_user
  end


  def mark_view!(user_id)
    self.user_profile_view_entries.find_by_end_user_id(user_id) ||
      self.user_profile_view_entries.create(:end_user_id => user_id)
  end

  def content_description(language)
    entry_user = EndUser.find_by_id(self.end_user_id)
    " \"%s\"'s User Profile" / entry_user.full_name
  end

  protected

  def create_url
    return nil unless self.end_user
    return nil if self.end_user.first_name.blank? && self.end_user.last_name.blank? && self.end_user.username.blank? 
    if !self.end_user.username.blank?
      url_try =  "#{self.end_user.username.downcase}" 
    else
      url_try = "#{self.end_user.first_name.to_s.downcase}-#{self.end_user.last_name.to_s.downcase}" 
    end
    url_try = url_try.to_s.downcase.gsub(/[ _]+/,"-").gsub(/[^a-z+0-9\-]/,"")
    url_base = url_try
    cnt = 1
    idx = 0
    while UserProfileEntry.find_by_url(url_try,:conditions => [ "user_profile_type_id=? AND end_user_id!=?",self.user_profile_type_id,self.end_user_id ])
      idx += 1 + (idx > 2 ? rand(50 * cnt) : 0)
      cnt += 1
      url_try = url_base + '-' + idx.to_s
    end
    url_try
  end

end
