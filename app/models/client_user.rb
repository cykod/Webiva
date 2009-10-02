# Copyright (C) 2009 Pascal Rettig.

require 'digest/sha1'

class ClientUser < SystemModel
  belongs_to :client
  
  validates_presence_of :username

  attr_accessor :password
  attr_accessor :activated_client
  
  serialize :options

  def before_create
    self.hashed_password = ClientUser.hash_password(self.password)
  end

  def before_save
    self.hashed_password = ClientUser.hash_password(self.password) if self.password && self.password.length > 0
  end
  
  def ClientUser.default_user
       usr = ClientUser.create
       return usr
  end
  
  def language
    (self.options || {})[:language] || Configuration.languages[0]  
  end
  
  def self.login_by_name(username,password,client_id)
    hashed_password = hash_password(password || "")
    find(:first,
         :conditions => ["username = ? and hashed_password =? AND (system_admin=1 OR client_id=?)",
                        username,hashed_password,client_id])
  end

  def end_user
    return @end_user if @end_user
    @end_user = EndUser.find(:first,:conditions => [ 'client_user_id = ?',self.id ])
    if(!@end_user)
      @end_user = EndUser.new(:first_name => 'Administrative',:last_name => 'User', :hashed_password => 'Invalid',:user_class_id => UserClass.client_user_class_id, :registered => true )
      @end_user.client_user_id = self.id
      @end_user.save(false)
    end
    @end_user
  end
  
  # For a client user, the permission object is the same as 
  # the user
  def user_class
    UserClass.client_user_class
  end

  def user_class_id
    UserClass.client_user_class.id
  end
  
  def registered?
    true
  end
  
  def user_profile
    self
  end

  def attempt_login
    ClientUser.login_by_name(self.username,self.password,self.client_id)
  end

  def override_client(client_id)
    self.client_id = client_id
    self.client.reload
  end
  
  # Must provide a 'name' attribute or function
  def name
    self.username
  end
  
  
  def identifier_name
    "CLIENT USER:#{self.username} (#{self.id})"
  end
  
  # All User classes 
  # Must provide an integer user_class id
  # Used for page caching
  def user_class_id
    UserClass.client_user_class_id
  end

  def validate_password(pw)
    return ClientUser.hash_password(pw) == self.hashed_password
  end

  private

  def self.hash_password(pw) 
    Digest::SHA1.hexdigest(pw)
  end
end
