# Copyright (C) 2009 Pascal Rettig.

class UserClass < DomainModel
  @@initialized = false
  
  @@built_in_classes = { 1 => [ 'anonymous', 'Anonymous', 'Unregistered Visitors to the site', false],
                        2 =>  [ 'client_user', 'Admin User', 'Administrative users with full access', true],
                        3 =>  [ 'domain_user', 'Editor',  'Default class for website editors', true ],
                        4 => [ 'default_user' , 'Default', 'Default class for registered users', false ] }
  

  include SiteAuthorizationEngine::Actor
  

  has_many :end_users

 
  def self.get_class(name,built_in = false)
    UserClass.initializor unless @@initialized
    clss = self.find_by_name(name)
    clss = self.create(:name => name, :built_in => built_in) unless clss
    clss
  end
  
  def self.create_built_in_classes
    @@built_in_classes.each do |idx,cls|
      UserClass.find_by_id(idx) || UserClass.create(:id => idx, :name => cls[1], :built_in => true, :editor => cls[3])
    end  
  end
  
  def self.add_default_editor_permissions
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
  
  # Called the first time the class is loaded
  def self.initializor
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
  
  def self.find_site_user_classes
    self.find(:all,:conditions => [ 'id NOT IN(1,2)' ])
  end
  
  initializor
  
  def self.method_missing(method,*args)
    super
  end
  
  def name
    if self.built_in?
      super.t
    else
      super
    end
  end

  
  def description
    if self.built_in?
      @@built_in_classes[self.id][2].t
    else
      super
    end
  end
  
  def after_destroy
    self.end_users.each do |user|
      user.update_attribute(:user_class_id,4)
    end
  
  end
  
  def self.options(is_editor = false)
    self.find(:all,:order => 'id=4 DESC, name',:conditions => ['id > 2 && editor = ?',is_editor ]).collect do |cls|
      [ cls.name, cls.id ]
    end 
  end
  
  def self.all_options
    self.find(:all,:order => 'id=4 DESC, name',:conditions => ['id > 2' ]).collect do |cls|
      [ cls.name, cls.id ]
    end 
  end
end
