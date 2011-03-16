Factory.define :end_user, :class => EndUser do |d|
  d.sequence(:email) { |n| "user#{n}@test.dev" }
end

Factory.define :domain_log_visitor, :class => DomainLogVisitor do |d|
  d.sequence(:visitor_hash) { |n| "visitor_hash_#{n}" }
  d.ip_address '127.0.0.1'
  d.latitude 1.0
  d.longitude 1.0
  d.country 'US'
  d.region 'MA'
  d.city 'Boston'
  d.created_at Time.now
  d.updated_at Time.now
  d.end_user_id nil
end

Factory.define :domain_log_session, :class => DomainLogSession do |d|
  d.sequence(:session_id) { |n| "session_id_#{n}" }
  d.created_at Time.now
  d.page_count nil
  d.last_entry_at nil
  d.length nil
  d.ip_address '127.0.0.1'
  d.affiliate nil
  d.campaign nil
  d.origin nil
  d.affiliate_data nil
  d.association :domain_log_visitor_id, :factory => :domain_log_visitor
  d.domain_log_referrer_id nil
  d.query nil
  d.domain_id nil
  d.site_version_id nil
  d.updated_at Time.now
  d.user_level nil
  d.ignore false
  d.domain_log_source_id 6
  d.session_value nil
end

Factory.define :domain_log_entry, :class => DomainLogEntry do |d|
  d.user_id nil
  d.site_node_id nil
  d.node_path '/'
  d.page_path ''
  d.occurred_at Time.now
  d.end_user_action_id nil
  d.user_class_id 1
  d.association :domain_log_session_id, :factory => :domain_log_session
  d.http_status 200
  d.content_node_id nil
  d.domain_id nil
  d.site_version_id nil
  d.user_level nil
  d.value nil
end

Factory.define :domain_log_referrer, :class => DomainLogReferrer do |d|
  d.sequence(:referrer_domain) { |n| "www.test#{n}.com" }
  d.sequence(:referrer_path) { |n| "/page#{n}.html" }
  d.created_at Time.now
  d.updated_at Time.now
end

def create_domain_log_session(opts={})
  visitor = Factory(:domain_log_visitor, opts.slice(:end_user_id))
  opts[:domain_log_visitor_id] = visitor.id
  Factory(:domain_log_session, opts)
end

def create_domain_log_entry(session, opts={})
  opts[:user_id] = session.domain_log_visitor.end_user_id
  opts[:domain_log_session_id] = session.id
  Factory(:domain_log_entry, opts)
end

def setup_domain_log_sources
  # from db/migrate/20101101174337_add_has_target_entry_to_domain_log_group.rb
  DomainLogSource.connection.execute "INSERT INTO domain_log_sources (name, position, source_handler, options) VALUES('Affiliate', 1, 'domain_log_source/affiliate', ''), ('Email Campaign', 2, 'domain_log_source/email_campaign', ''), ('Social Network', 3, 'domain_log_source/social_network', ''), ('Search', 4, 'domain_log_source/search', ''), ('Referrer', 5, 'domain_log_source/referrer', ''), ('Type-in', 6, 'domain_log_source/type_in', '')"
end
