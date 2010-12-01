# Copyright (C) 2009 Pascal Rettig.

require 'digest/sha1'

# A system model that represents an admin-level user 
# in a client. Each client user will have complete privileges 
# in all of that client's domains and will be able to login
# with that username and password to any of the clients domains
#
# System admins will be able to login to any clients domains
# with the same privileges. 
class ClientUser < SystemModel
  belongs_to :client
  
  validates_presence_of :username
  validates_uniqueness_of :username

  validates_presence_of :client_id

  attr_accessor :password
  attr_accessor :activated_client
  
  serialize :options

  def before_save # :nodoc:
    if self.password && self.password.length > 0
      self.salt = self.class.generate_hash if self.salt.blank?
      self.hashed_password = ClientUser.hash_password(self.password, self.salt)
    end
  end

  def validate
    self.errors.add(:client_id, 'is missing') unless self.client

    if self.id.nil? && self.client
      self.errors.add_to_base('Max users for client') if self.client.available_client_users == 0
    end
  end

  # Returns the user's default language or returns
  # the first configured language on the site.
  def language
    (self.options || {})[:language] || Configuration.languages[0]  
  end
  
  # Attempts a login with a username, password and client_id
  # Return the user object if the login is sucessful, otherwise return nil
  def self.login_by_name(username,password,client_id)
    usr = find(:first,
               :conditions => ["username = ? and (system_admin=1 OR client_id=?)",username,client_id])
    hashed_password = self.hash_password(password || "", usr.salt) if usr
    if usr && usr.hashed_password == hashed_password
      usr = nil unless usr.system_admin? || usr.client_admin? || usr.domain_database_id.nil? || usr.domain_database_id == DomainModel.active_domain[:domain_database_id]
      usr
    else
      nil
    end
  end

  # Returns an end user object in the current database for creates 
  # a special "Administrative User" EndUser object linked to this client user id
  def end_user
    return @end_user if @end_user
    @end_user = EndUser.find(:first,:conditions => [ 'client_user_id = ?',self.id ])
    if(!@end_user)
      @end_user = EndUser.new(:first_name => username, :hashed_password => 'Invalid', :registered => true, :email => email )
      @end_user.user_class_id = UserClass.client_user_class_id
      @end_user.client_user_id = self.id
      @end_user.save(false)
    end
    @end_user
  end
  
  
  def attempt_login #:nodoc:
    ClientUser.login_by_name(self.username,self.password,self.client_id)
  end

  # Overrides the client for the current object
  # (used for system admins to view other client databases)
  def override_client(client_id)
    self.client_id = client_id
    self.client.reload
  end
  
  # Must provide a 'name' attribute or function
  def name
    self.username
  end
  
  
  def identifier_name #:nodoc:
    "CLIENT USER:#{self.username} (#{self.id})"
  end
  
  def validate_password(pw) #:nodoc:
    return ClientUser.hash_password(pw, self.salt) == self.hashed_password
  end

  def domain_database_select_options
    if self.system_admin?
      DomainDatabase.find(:all).collect { |db| [db.domain_name, db.id] }
    else
      self.client.domain_database_select_options
    end
  end

  private

  def self.hash_password(pw,salt=nil) #:nodoc:
    if !salt.blank?
      Digest::SHA1.hexdigest(salt.to_s + pw)
    else
      Digest::SHA1.hexdigest(pw)
    end
  end
end
