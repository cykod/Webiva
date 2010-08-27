
class DomainLogGroup < DomainModel
  has_many :domain_log_stats, :dependent => :delete_all

  named_scope :for_target, lambda { |type, id| {:conditions => {:target_type => type, :target_id => id}} }
  named_scope :with_type, lambda { |type| {:conditions => {:stat_type => type}} }
  named_scope :started_at, lambda { |time| {:conditions => {:started_at => time}} }
  named_scope :with_duration, lambda { |duration| {:conditions => {:duration => duration}} }

  def expired?
    self.expires_at && self.expires_at < Time.now
  end

  def self.stats(target, from, duration, intervals, opts={})
    groups = []
    (1..intervals).each do |i|
      scope = yield from, duration
      groups << self.fetch_group(target, from, duration, scope, opts)
      from += duration
    end
    groups
  end

  def self.fetch_group(target, started_at, duration, scope, opts={})
    target_type = target.is_a?(String) ? target : target.class.to_s
    target_id = target.is_a?(String) ? nil : target.id
    duration = duration.to_i

    # NOTE: remember to optimize, need to check for the stats using target_id nil first, then if not results check for target_id if set
    group_scope = DomainLogGroup.started_at(started_at).with_duration(duration).for_target(target_type, target_id)
    group_scope = group_scope.with_type(opts[:type]) if opts[:type]
    group = group_scope.first

    if group && group.expired?
      group.destroy
      group = nil
    end

    return group if group

    results = scope.find :all

    attributes = {
      :target_type => target_type,
      :target_id => target_id,
      :stat_type => opts[:type],
      :started_at => started_at,
      :duration => duration
    }

    attributes[:expires_at] = 5.minutes.since if (started_at + duration) > Time.now
    group = DomainLogGroup.create attributes

    results.each do |result|
      group.domain_log_stats.create result.attributes.slice('target_id', 'visits', 'hits', 'leads', 'conversions', 'stat1', 'stat2')
    end

    group
  end
end
