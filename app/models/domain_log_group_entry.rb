
class DomainLogGroupEntry < DomainModel
  def self.push_value(value)
    DomainLogGroupEntry.first(:conditions => {:target_value => value}) || DomainLogGroupEntry.create(:target_value => value)
  end
end
