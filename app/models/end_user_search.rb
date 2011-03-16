
class EndUserSearch
  attr_accessor :terms, :offset, :page, :per_page, :user_segment, :offsets

  def search(opts={})
    scope = EndUserCache.search self.terms
    if self.user_segment
      self.offsets << self.offset unless self.offsets.include?(self.offset)
      @new_offset, @users = self.user_segment.search opts.merge(:scope => scope, :offset => self.offset, :limit => self.per_page)
      if @users.length >= self.per_page
        self.offsets << (@new_offset+1) unless self.offsets.include?(@new_offset+1)
      end
      [@new_offset, @users]
    else
      @pages, ids = scope.paginate(self.page, :select => 'end_user_id')
      ids = ids.collect { |cache| cache[:end_user_id] }
      users_by_id = EndUser.find(:all, opts.merge(:conditions => {:id => ids})).index_by(&:id)
      @users = ids.map { |id| users_by_id[id] }
      @users.compact! # just incase the user was deleted and the cache wasn't
      [@pages, @users]
    end
  end

  def total
    if self.user_segment
      self.offsets.length * self.per_page - (self.per_page - @users.length)
    else
      @pages[:total]
    end
  end

  def users
    @users
  end
end
