
class EndUserCache < DomainModel
  belongs_to :end_user
  validates_presence_of :end_user_id

  named_scope :search, lambda { |query| {:conditions => ['MATCH (data) AGAINST (?)', query], :order => "MATCH (data) AGAINST (#{self.quote_value(query)}) DESC"} }

  def before_save
    self.data = self.get_end_user_data.delete_if { |v| v.blank? }.join(' ')
  end

  def get_end_user_data
    data = [
      self.end_user.email,
      self.end_user.name,
      self.end_user.user_class.name,
      self.end_user.source,
      self.end_user.registered? ? 'registered' : nil,
      self.end_user.tag_names
    ]
  end

  def self.reindex
    EndUser.find_in_batches do |users|
      users.each { |user| user.save }
    end
  end
end
