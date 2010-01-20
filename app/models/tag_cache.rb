# Copyright (C) 2009 Pascal Rettig.


class TagCache < DomainModel #:nodoc:all
  set_table_name :tag_cache

  belongs_to :end_user

end
