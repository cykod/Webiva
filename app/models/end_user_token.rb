# Copyright (C) 2009 Pascal Rettig.



class EndUserToken < DomainModel

  belongs_to :end_user
  belongs_to :access_token

  belongs_to :target, :polymorphic => true


  named_scope :active, :conditions => '(`valid_until` IS NULL OR `valid_until` > NOW()) AND (`valid_at` IS NULL OR `valid_at` < NOW())'


  def name
    self.access_token.token_name if self.access_token
  end
end
