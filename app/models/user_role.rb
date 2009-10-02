# Copyright (C) 2009 Pascal Rettig.

class UserRole < DomainModel
  belongs_to :authorized, :polymorphic => true
  
  belongs_to :user_class, :class_name => 'UserClass', 
  :foreign_key => 'authorized_id',
  :conditions => 'authorized_type = "UserClass"'

  belongs_to :access_token, :class_name => 'AccessToken',
  :foreign_key => 'authorized_id',
  :conditions => 'authorized_type = "AccessToken"'

  
  belongs_to :role
  
  def identifier
    self.authorized_type.underscore + "/" + self.authorized_id.to_s
  end

  def name
    if self.authorized_type=='AccessToken'
      'Access Token: '.t +  self.authorized.name
    elsif self.authorized_type=='UserClass'
      'Profile: '.t +  self.authorized.name
    end
    
  end

  def position
    0
  end
end
