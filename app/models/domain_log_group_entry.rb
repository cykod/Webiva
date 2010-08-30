
class DomainLogGroupEntry < DomainModel
  def self.push_value(value)
    DomainLogGroupEntry.first(:conditions => {:target_value => value}) || DomainLogGroupEntry.create(:target_value => value)
  end

  def self.process_stats(group, opts={})
    group_by = opts[:group] || group.stat_type
    index_by = opts[:index_by] || :target_value
    DomainLogGroup.update_hits group, :group => group_by, :index_by => index_by
  end
end
