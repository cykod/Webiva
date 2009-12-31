# Copyright (C) 2009 Pascal Rettig.


=begin rdoc
Access tokens grant additional permissions to EndUsers they are added do. Users
may have multiple access tokens, and each token can have different start and expiration dates,
as well as a "Target" which can verifiy access

AccessToken ties into the SiteAuthorizationEngine as an Actor, i.e. they have different permissions 
that are added to them. 
=end
class AccessToken < DomainModel

  include SiteAuthorizationEngine::Actor
  
  validates_presence_of :token_name

  has_many :user_roles, :as => :authorized

  has_many :end_user_tokens, :dependent => :destroy
  has_many :end_users, :through => :end_user_tokens

  serialize :role_cache

  # Alias for token_name
  def name
    self.token_name
  end

  # Return the role ids from the cache if possible
  def cached_role_ids
    if self.role_cache.is_a?(Array)
      self.role_cache
    else
      self.role_ids
    end
  end

  def before_save # :nodoc: 
    self.role_cache = self.role_ids
  end
  

  # returns a select-friendly list of options for editor tokens
  def self.editor_token_options
    self.select_options(:conditions => 'editor=1')
  end

  # returns a select-friendly list of options for non-editor tokens
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
