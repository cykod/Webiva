
class DomainLogStat < DomainModel
  belongs_to :domain_log_group

  def target_type
    self.domain_log_group.has_target_entry? ? 'DomainLogGroupEntry' : self.domain_log_group.target_type
  end

  def target
    @target ||= self.target_type.constantize.find_by_id self.target_id
  end

  def target_value=(value)
    self.target_id = DomainLogGroupEntry.push_value(value).id
  end

  def target_value
    return nil unless self.target_type == 'DomainLogGroupEntry'
    self.target.target_value
  end
end
