# Copyright (C) 2010 Cykod LLC

class UserProfileType < DomainModel 
# after_create self.avilable_content_model_fields
  has_many :user_profile_type_user_classes, :dependent => :destroy
  has_many :user_classes, :through => :user_profile_type_user_classes

  has_many :user_profile_entries,  :dependent => :destroy, :order => 'user_profile_entries.id'

  belongs_to :content_model
  belongs_to :content_model_field

  after_save :update_user_classes
  after_save :update_entries_content_model

  content_node_type :user_profile, "UserProfileEntry", :content_name => :name,:title_field => :create_full_name, :url_field => :url

  validate :check_content_model_and_field


  def content_admin_url(pe)
    { :controller => '/user_profile/manage', :action => 'user',:path => [ pe ] }
  end

  def content_model_field_options
    flds = ContentModelField.find(:all, :conditions => {:content_model_id => self.content_model_id, :field_type => "belongs_to" } )
    flds = flds.select { |fld| fld.relation_class == EndUser }
    available_fields = flds.map { |fld| [ fld.name, fld.id ] }
  end

  def content_model_field_name
    @content_model_field_name ||= self.content_model_field.field
  end
  def self.match_classes(cid)
    UserProfileTypeUserClass.find(:all, :conditions => {:user_class_id => cid} ).map(&:user_profile_type_id)
  end

  def self.matching_types_options(cid)
    UserProfileTypeUserClass.find(:all, :conditions => {:user_class_id => cid} ).map { |uc| [ uc.user_profile_type.name, uc.user_profile_type.id ] }
  end

  def self.create_default_profile_type
    default_type = UserProfileType.create(:name => 'Default Profile Type'.t)
    UserProfileTypeUserClass.create(:user_class_id => UserClass.default_user_class_id, :user_profile_type_id => default_type.id)
  end

  def user_classes=(val)
    @cached_class_ids = val.map { |val| val['id'] }.reject(&:blank?).map(&:to_i)
  end

  # Return all fields except the one we're using for linking
  def display_content_model_fields
    if self.content_model
      self.content_model.content_model_fields.select { |fld| fld.id != self.content_model_field_id }
    else
      []
    end
  end

  def content_type_name
    "User Profile Type".t
  end


  def self.import_fields
    available_fields = UserProfileType.all.inject([]) do |acc,upt| 
       acc.concat(upt.display_content_model_fields.map { |fld| [ upt.id, fld ] })
    end
     
    fields =  available_fields.map do |fld|
      [ "user_profile_field_#{fld[0]}_#{fld[1].id}", "User Profile - #{fld[1].name}", [ fld[1].name.downcase,fld[1].field.to_s.downcase ], :profile ]
    end
  end


  def paginate_users(page,options={})

    conds = { :published => 1 }
    conds['end_users.registered'] = 1 if options[:registered_only]
    conds[:protected] = 0 if options[:hide_protected]

    pages,users = UserProfileEntry.paginate(page,:joins => [ :end_user ], :conditions => conds, :order => options[:order], :include => :end_user)
    

    if self.content_model 
      cls = self.content_model.model_class

      model_attributes = { self.content_model_field_name => users.map(&:end_user_id) }

      model_entries = cls.find(:all,:conditions => model_attributes).index_by(&(self.content_model_field_name.to_sym))

      users.each do |usr|
        entry = model_entries[usr.end_user_id]
        if entry
          usr.content_model_entry_cache = entry 
        else
          usr.content_model_entry_cache = cls.new( self.content_model_field_name => usr.end_user_id)
        end
      end
    end

    [ pages,users ]

  end


  protected

  def update_entries_content_model
    if self.content_model_id_changed?
      self.user_profile_entries.update_all "content_model_id = #{self.content_model_id ? self.content_model_id : 'NULL'}"
    end
  end

  def update_user_classes
    if @cached_class_ids
      self.user_profile_type_user_classes = []
      @cached_class_ids.each do |cid|
        self.user_profile_type_user_classes.create(:user_class_id => cid)
      end
    end
  end

  def check_content_model_and_field
    if self.content_model && !self.content_model_field
      self.errors.add(:content_model_field_id, " is missing")
    end
  end

end
