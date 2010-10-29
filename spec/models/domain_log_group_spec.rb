require File.dirname(__FILE__) + "/../spec_helper"
require File.dirname(__FILE__) + "/../domain_log_spec_helper"

describe DomainLogGroup do

  reset_domain_tables :domain_log_group, :domain_log_stat, :domain_log_group_entry,
    :end_user, :end_user_cache, :domain_log_visitor, :domain_log_session, :domain_log_entry, :domain_log_referrer

  describe "Traffic Stats" do
    before(:each) do
      created_at = 5.hours.ago
      user = Factory(:end_user)
      session = create_domain_log_session(:end_user_id => user.id, :created_at => created_at)
      (1..5).each do |n|
        create_domain_log_entry(session, :occurred_at => created_at - n.minutes)
      end

      created_at = 4.hours.ago
      session = create_domain_log_session(:created_at => created_at)
      (1..20).each do |n|
        create_domain_log_entry(session, :occurred_at => created_at - n.minutes)
      end
    end

    it "should calculate site traffic" do
      DomainLogGroup.stats('DomainLogEntry', Time.now.at_midnight, 1.day, 1, :stat_type => 'traffic') do |from, duration|
        DomainLogEntry.between(from, from+duration).scoped(:select => "count(*) as hits, count( DISTINCT domain_log_session_id ) as visits")
      end

      stat = DomainLogStat.last
      stat.visits.should == 2
      stat.hits.should == 25
    end
  end
end
