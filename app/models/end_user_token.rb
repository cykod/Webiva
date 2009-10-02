# Copyright (C) 2009 Pascal Rettig.



class EndUserToken < DomainModel

  belongs_to :end_user
  belongs_to :access_token

  def name
    self.access_token.token_name if self.access_token
  end
end
