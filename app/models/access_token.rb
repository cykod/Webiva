# Copyright (C) 2009 Pascal Rettig.



class AccessToken < DomainModel

  include SiteAuthorizationEngine::Actor
  
  validates_presence_of :token_name

  has_many :user_roles, :as => :authorized

  has_many :end_user_tokens, :dependent => :destroy
  has_many :end_users, :through => :end_user_tokens

  has_many :roles, :through => :user_roles

  def name
    self.token_name
  end

  def self.editor_token_options
    self.select_options(:conditions => 'editor=1')
  end

  def self.user_token_options
   self.select_options(:conditions => 'editor=0')
  end

  # Pass it an array of like:
  # [{"access_token_id"=>""}, {"access_token_id"=>"1"},
  # {"access_token_id"=>""}, {"access_token_id"=>"2"}]
  # and it'll return only editor ones
  def self.filter_out_editor_tokens(atr)
    atr ||= []
    tokens = AccessToken.find(:all,:conditions => 'editor=0',:select => 'id').map(&:id)
    atr.select do |tkn|
      tokens.include?(tkn[:access_token_id].to_i)
    end
  end
  
  
end
