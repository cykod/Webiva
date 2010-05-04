# Copyright (C) 2010 Cykod LLC

class UserProfileType < DomainModel 
# after_create self.avilable_content_model_fields
  has_many :user_profile_type_user_classes, :dependent => :destroy
  has_many :user_classes, :through => :user_profile_type_user_classes

  has_many :user_profile_entries,  :dependent => :destroy, :order => 'user_profile_entries.id'

  belongs_to :content_model
  belongs_to :content_model_field

  after_save :update_user_classes

  content_node_type :user_profile, "UserProfileEntry", :content_name => :name,:title_field => :create_full_name, :url_field => :url

  validate :check_content_model_and_field


  def content_admin_url(pe)
    { :controller => '/user_profile/manage', :action => 'view',:path => [ pe ] }
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


  protected

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
