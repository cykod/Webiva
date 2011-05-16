# Copyright (C) 2009 Pascal Rettig.



class EndUserCookie < DomainModel

  validates_presence_of :end_user_id, :cookie
  
  belongs_to :end_user
  
  def self.generate_cookie(usr,valid_until=nil)
    ck = self.create(:end_user_id => usr.id,:valid_until => valid_until || 2.weeks.from_now,:cookie => DomainModel.generate_hash)
    ck.cookie
  end

  def self.generate_api_key(usr)
    ck = self.create(:end_user_id => usr.id,:valid_until => nil,:cookie => DomainModel.generate_hash)
    ck.cookie
  end
  
  def self.use_cookie(ck)
    cookie = self.find_by_cookie(ck)
    if cookie
      usr = cookie.end_user 
      cookie.destroy
      return usr if cookie.valid_until > Time.now
    end
    return nil
  end

  def self.kill_user_cookies(usr)
    EndUserCookie.find(:all,:conditions => { :end_user_id => usr.id }).each { |ck| ck.destroy } 
  end
end
