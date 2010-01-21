# Copyright (C) 2009 Pascal Rettig.

require "digest/sha1"

# Used for a centralized login system among multiple domains
class EditorLogin < SystemModel 

  attr_accessor :password
  
  belongs_to :domain
  
  def generate_login_hash!
      val = Time.now.to_s+(Process.pid + Process.pid + self.object_id).to_s
      self.update_attribute(:login_hash,Digest::SHA1.hexdigest(val))
  end

  def attempt_login
      EditorLogin.find(:first,:conditions => ['email =? AND hashed_password=?',self.email,EndUser.hash_password(self.password)])
  end

end
