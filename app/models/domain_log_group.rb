
class DomainLogGroup < DomainModel
  has_many :domain_log_stats, :dependent => :delete_all

  named_scope :for_target, lambda { |type, id| {:conditions => {:target_type => type, :target_id => id}} }
  named_scope :with_type, lambda { |type| {:conditions => {:stat_type => type}} }
  named_scope :started_at, lambda { |time| {:conditions => {:started_at => time}} }
  named_scope :with_duration, lambda { |duration| {:conditions => {:duration => duration.to_i}} }

  def expired?
    self.expires_at && self.expires_at < Time.now
  end

  def ended_at
    @ended_at ||= self.started_at + duration
  end

  def self.stats(target_type, from, duration, intervals, opts={})
    groups = []
    (1..intervals).each do |i|
      group = self.find_group(target_type, from, duration, opts)
      if group
        groups << group
      else
        scope = yield from, duration
        groups << self.create_group(target_type, from, duration, scope, opts)
      end
      from += duration
    end
    groups
  end

  def self.find_group(target_type, started_at, duration, opts={})
    target_id = opts[:target_id]

    group = DomainLogGroup.started_at(started_at).with_duration(duration).for_target(target_type, nil).with_type(opts[:type]).first

    if group && group.expired?
      if target_id.nil?
        group.destroy
        return nil
      end
    end

    if group.nil? && target_id
      group = DomainLogGroup.started_at(started_at).with_duration(duration).for_target(target_type, target_id).with_type(opts[:type]).first
      if group && group.expired?
        group.destroy
        return nil
      end
    end

    group.target_id = target_id if group && target_id
    group
  end

  def self.create_group(target_type, started_at, duration, scope, opts={})
    target_id = opts[:target_id]

    results = scope.find :all

    attributes = {
      :target_type => target_type,
      :target_id => target_id,
      :stat_type => opts[:type],
      :started_at => started_at,
      :duration => duration.to_i
    }

    attributes[:expires_at] = 5.minutes.since if (started_at + duration) > Time.now
    group = DomainLogGroup.create attributes

    results.each do |result|
      stat = group.domain_log_stats.create result.attributes.slice('target_id', 'target_value', 'visits', 'hits', 'subscribers', 'leads', 'conversions', 'stat1', 'stat2')
    end

    opts[:class].send(opts[:process_stats], group, opts) if opts[:process_stats]

    group
  end

  def target_stats(target_id=nil)
    target_id ||= self.target_id
    self.domain_log_stats.find(:all, :conditions => {:target_id => target_id})
  end

  def self.update_hits(group, opts={})
    return unless opts[:group]

    index_by = opts[:index_by] || :target_id

    target_ids = group.domain_log_stats.collect(&index_by).sort.uniq
    return if target_ids.empty?

    domain_log_session_ids = DomainLogSession.find(:all, :select => 'id', :conditions => {opts[:group] => target_ids}).collect(&:id)
    DomainLogSession.update_entry_stats domain_log_session_ids

    page_counts = DomainLogSession.sum(:page_count, :conditions => {:id => domain_log_session_ids}, :group => opts[:group])

    group.domain_log_stats.index_by(&index_by).each do |target_id, stat|
      stat.update_attribute :hits, page_counts[target_id]
    end
  end

  def self.traffic_chart_data(groups, opts={})
    to = groups[0].started_at
    from = groups[-1].ended_at

    opts[:label] ||= '%I:%M'

    groups = groups.sort { |a,b| b.started_at <=> a.started_at } if opts[:desc]

    uniques = []
    hits = []
    labels = []
    groups.each do |group|
      stat = group.domain_log_stats[0]
      if stat
        uniques << stat.visits
        hits << stat.hits
      else
        uniques << 0
        hits << 0
      end
      labels << group.ended_at.strftime(opts[:label])
      break if opts[:update_only]
    end

    format = opts[:format] || '%b %e, %Y %I:%M%P'
    data = { :from => from.strftime(format), :to => to.strftime(format), :uniques => uniques, :visits => uniques, :hits => hits, :labels => labels }
  end
end
