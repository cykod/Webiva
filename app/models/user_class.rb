# Copyright (C) 2009 Pascal Rettig.


# Called a "User Profile" on the front end (sorry) every EndUser is a member of one
# UserClass - even users who aren't logged in a members of the "anonymous" user class
#
# The site authorization system uses UserClass and AccessToken's to control access to 
# both pages of the backend and various pages on the frontend.
class UserClass < DomainModel
  @@initialized = false
  
  @@built_in_classes = { 1 => [ 'anonymous', 'Anonymous', 'Unregistered Visitors to the site', false],
                        2 =>  [ 'client_user', 'Admin User', 'Administrative users with full access', true],
                        3 =>  [ 'domain_user', 'Editor',  'Default class for website editors', true ],
                        4 => [ 'default_user' , 'Default', 'Default class for registered users', false ] }
  

  include SiteAuthorizationEngine::Actor
  
  serialize :role_cache

  has_many :end_users

  # Return or create a class by name
  def self.get_class(name,built_in = false)
    UserClass.initializor unless @@initialized
    clss = self.find_by_name(name)
    clss = self.create(:name => name, :built_in => built_in) unless clss
    clss
  end
  
  def self.create_built_in_classes #:nodoc:
    @@built_in_classes.each do |idx,cls|
      UserClass.find_by_id(idx) || UserClass.create(:name => cls[1], :built_in => true, :editor => cls[3]).update_attribute(:id,idx)
    end  
  end
  
  
  def self.add_default_editor_permissions #:nodoc:
    editor  = self.domain_user_class
    OptionsController.registered_permissions.each do |cat,elems|
        elems.each do |elem|
          editor.has_role(cat.to_s + "_" + elem[0].to_s)
        end
    end
    EditController.registered_permissions.each do |cat,elems|
        elems.each do |elem|
          editor.has_role(cat.to_s + "_" + elem[0].to_s)
        end
    end
  end

  def cached_role_ids #:nodoc:
#    if self.role_cache.is_a?(Array)
#      self.role_cache
#    else
      self.role_ids
#    end
  end

  def before_save #:nodoc:
    #self.role_cache = self.role_ids
  end
  
  # Called the first time the class is loaded
  def self.initializor #:nodoc:
    sing = class << self; self; end

    @@built_in_classes.each do |idx,cls|
      sing.send :define_method, cls[0] + "_class" do 
	UserClass.find_by_id(idx)
      end 
      sing.send :define_method, cls[0] + "_class_id" do 
	idx
      end 
      
    end
  end
  
  # Return all the non-admin or anonymous user classes
  def self.find_site_user_classes
    self.find(:all,:conditions => [ 'id NOT IN(1,2)' ])
  end
  
  initializor
  
  
  def name #:nodoc:
    if self.built_in?
      super.t
    else
      super
    end
  end

  
  def description #:nodoc:
    if self.built_in?
      @@built_in_classes[self.id][2].t
    else
      super
    end
  end
  
  def after_destroy #:nodoc:
    self.end_users.each do |user|
      user.update_attribute(:user_class_id,4)
    end
  
  end
  
  # Return a list of select-friendly options, either of editor classes or non-editor classes
  def self.options(is_editor = false)
    self.find(:all,:order => 'id=4 DESC, name',:conditions => ['id > 2 && editor = ?',is_editor ]).collect do |cls|
      [ cls.name, cls.id ]
    end 
  end
  
  # Return a full list of all user profiles in a select friendly list
  def self.all_options
    self.find(:all,:order => 'id=4 DESC, name',:conditions => ['id > 2' ]).collect do |cls|
      [ cls.name, cls.id ]
    end 
  end
end
