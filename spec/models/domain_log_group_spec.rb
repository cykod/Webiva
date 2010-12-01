require File.dirname(__FILE__) + "/../spec_helper"
require File.dirname(__FILE__) + "/../domain_log_spec_helper"

describe DomainLogGroup do

  reset_domain_tables :domain_log_group, :domain_log_stat, :domain_log_group_entry

  def delete_all_stat_data
    EndUser.destroy_all
    DomainLogVisitor.delete_all
    DomainLogSession.delete_all
    DomainLogReferrer.delete_all
    DomainLogEntry.delete_all
    SiteVersion.delete_all
    SiteNodeModifier.delete_all
    SiteNode.delete_all
    PageRevision.delete_all
  end

  def create_session(created_at, num_entries=5, new_user=true, opts={})
    time_between_requests = 1.minute
    created_at += 1.minute

    site_node_id = opts.delete(:site_node_id)

    end_user_id = new_user ? Factory(:end_user).id : nil

    session = create_domain_log_session(opts.merge(:end_user_id => end_user_id, :created_at => created_at))

    occurred_at = created_at
    (1..num_entries).each do |n|
      create_domain_log_entry(session, :occurred_at => occurred_at, :site_node_id => site_node_id)
      occurred_at += time_between_requests
    end

    session
  end

  describe "Traffic Stats" do
    before do
      delete_all_stat_data

      create_session 2.days.ago, 3
      create_session 2.days.ago, 1, false

      session = create_session 5.hours.ago
      session.update_attribute :user_level, EndUser::UserLevel::SUBSCRIBED
      create_domain_log_entry(session, :occurred_at => 3.hours.ago, :user_level => EndUser::UserLevel::SUBSCRIBED)

      session = create_session 4.hours.ago, 20, false
      session.update_attribute :user_level, EndUser::UserLevel::LEAD
      create_domain_log_entry(session, :occurred_at => 2.hours.ago, :user_level => EndUser::UserLevel::LEAD)

      session = create_session 4.hours.ago, 7, false
      session.update_attribute :user_level, EndUser::UserLevel::LEAD
      create_domain_log_entry(session, :occurred_at => 2.hours.ago, :user_level => EndUser::UserLevel::LEAD)
    end

    after do
      delete_all_stat_data
    end

    it "should calculate site traffic for past day" do
      start_time = 1.day.ago

      assert_difference 'DomainLogGroup.count', 1 do
        assert_difference 'DomainLogStat.count', 1 do
          DomainLogGroup.stats('DomainLogEntry', start_time, 1.day, 1, :stat_type => 'traffic') do |from, duration|
            DomainLogEntry.between(from, from+duration).hits_n_visits(nil)
          end
        end
      end

      stat = DomainLogStat.last
      stat.visits.should == 3
      stat.hits.should == 35
      stat.subscribers.should == 1
      stat.leads.should == 2
      stat.conversions.should == 0
      stat.stat1.should be_nil
      stat.stat2.should be_nil

      assert_difference 'DomainLogGroup.count', 0 do
        assert_difference 'DomainLogStat.count', 0 do
          DomainLogGroup.stats('DomainLogEntry', start_time, 1.day, 1, :stat_type => 'traffic') do |from, duration|
            DomainLogEntry.between(from, from+duration).hits_n_visits(nil)
          end
        end
      end

      stat = DomainLogStat.last
      stat.visits.should == 3
      stat.hits.should == 35
      stat.subscribers.should == 1
      stat.leads.should == 2
      stat.conversions.should == 0
      stat.stat1.should be_nil
      stat.stat2.should be_nil
    end

    it "should calculate site traffic for past week" do
      DomainLogGroup.stats('DomainLogEntry', 7.day.ago, 1.week, 1, :stat_type => 'traffic') do |from, duration|
        DomainLogEntry.between(from, from+duration).hits_n_visits(nil)
      end

      stat = DomainLogStat.last
      stat.visits.should == 5
      stat.hits.should == 39
      stat.subscribers.should == 1
      stat.leads.should == 2
      stat.conversions.should == 0
      stat.stat1.should be_nil
      stat.stat2.should be_nil
    end

    it "should calculate site traffic for past 2 day" do
      assert_difference('DomainLogGroup.count', 2) do
        assert_difference('DomainLogStat.count', 2) do
          DomainLogGroup.stats('DomainLogEntry', 2.day.ago, 1.day, 2, :stat_type => 'traffic') do |from, duration|
            DomainLogEntry.between(from, from+duration).hits_n_visits(nil)
          end
        end
      end

      stat = DomainLogStat.first
      stat.visits.should == 2
      stat.hits.should == 4
      stat.subscribers.should == 0
      stat.leads.should == 0
      stat.conversions.should == 0
      stat.stat1.should be_nil
      stat.stat2.should be_nil

      stat = DomainLogStat.last
      stat.visits.should == 3
      stat.hits.should == 35
      stat.subscribers.should == 1
      stat.leads.should == 2
      stat.conversions.should == 0
      stat.stat1.should be_nil
      stat.stat2.should be_nil
    end
  end

  describe "Affiliate Stats" do
    before do
      delete_all_stat_data
      
      session = create_session 4.hours.ago, 7, false, :affiliate => 'affiliate1', :campaign => 'campaign1', :origin => 'origin1', :affiliate_data => 'data1', :user_level => EndUser::UserLevel::CONVERSION
      create_domain_log_entry(session, :occurred_at => 3.hours.ago, :user_level => EndUser::UserLevel::CONVERSION)

      create_session 6.hours.ago, 2, false, :affiliate => 'affiliate1', :campaign => 'campaign2'
      create_session 4.hours.ago, 2, false, :affiliate => 'affiliate1', :campaign => 'campaign2'
      create_session 3.hours.ago, 2, false, :affiliate => 'affiliate2', :campaign => 'campaign1'
      create_session 4.hours.ago, 2, true, :affiliate => 'affiliate2', :campaign => 'campaign1'
      create_session 2.hours.ago, 2, false, :affiliate => 'affiliate3', :campaign => 'campaign1'
      create_session 1.hours.ago, 2, true, :affiliate => 'affiliate3', :campaign => 'campaign2', :origin => 'origin2'
      create_session 1.hours.ago, 2, false, :affiliate => 'affiliate3', :campaign => 'campaign2', :origin => 'origin3', :affiliate_data => 'user2'
    end

    after do
      delete_all_stat_data
    end

    it "calculate basic traffic stats" do
      start_time = 1.day.ago

      assert_difference 'DomainLogGroup.count', 1 do
        assert_difference 'DomainLogStat.count', 1 do
          DomainLogGroup.stats('DomainLogEntry', start_time, 1.day, 1, :stat_type => 'traffic') do |from, duration|
            DomainLogEntry.between(from, from+duration).hits_n_visits(nil)
          end
        end
      end

      stat = DomainLogStat.last
      stat.visits.should == 8
      stat.hits.should == 22
      stat.subscribers.should == 0
      stat.leads.should == 0
      stat.conversions.should == 1
      stat.stat1.should be_nil
      stat.stat2.should be_nil
    end

    it "should be able to get affiliates" do
      affiliates, campaigns, origins = DomainLogSession.get_affiliates
      affiliates.should include('affiliate1')
      affiliates.should include('affiliate2')
      affiliates.should include('affiliate3')
      campaigns.should include('campaign1')
      campaigns.should include('campaign2')
      origins.should include('origin1')
      origins.should include('origin2')
      origins.should include('origin3')
    end

    it "should be able to get affiliate stats" do
      from = 1.day.ago
      duration = 1.day
      intervals = 1

      assert_difference 'DomainLogGroup.count', 1 do
        assert_difference 'DomainLogStat.count', 3 do
          assert_difference 'DomainLogGroupEntry.count', 3 do
            @groups = DomainLogSession.affiliate(from, duration, intervals)
          end
        end
      end

      group = @groups[0]
      group.target_type.should == 'DomainLogSession'
      group.target_id.should be_nil
      group.has_target_entry?.should be_true
      group.stat_type.should == "a::c::o::affiliate_traffic"
      group.started_at.should == from
      group.duration.should == duration
      group.expires_at.should be_nil

      entry = DomainLogGroupEntry.find_by_target_value 'affiliate1'
      entry.should_not be_nil
      stat = group.domain_log_stats.find_by_target_id entry.id
      stat.should_not be_nil
      stat.hits.should == 12
      stat.visits.should == 3

      entry = DomainLogGroupEntry.find_by_target_value 'affiliate2'
      entry.should_not be_nil
      stat = group.domain_log_stats.find_by_target_id entry.id
      stat.should_not be_nil
      stat.hits.should == 4
      stat.visits.should == 2

      entry = DomainLogGroupEntry.find_by_target_value 'affiliate3'
      entry.should_not be_nil
      stat = group.domain_log_stats.find_by_target_id entry.id
      stat.should_not be_nil
      stat.hits.should == 6
      stat.visits.should == 3
    end

    it "should be able to get campaign stats" do
      from = 1.day.ago
      duration = 1.day
      intervals = 1
      display = 'campaign'

      assert_difference 'DomainLogGroup.count', 1 do
        assert_difference 'DomainLogStat.count', 2 do
          assert_difference 'DomainLogGroupEntry.count', 2 do
            @groups = DomainLogSession.affiliate(from, duration, intervals, :display => display)
          end
        end
      end

      group = @groups[0]
      group.target_type.should == 'DomainLogSession'
      group.target_id.should be_nil
      group.stat_type.should == "a::c::o::#{display}_traffic"
      group.started_at.should == from
      group.duration.should == duration
      group.expires_at.should be_nil

      entry = DomainLogGroupEntry.find_by_target_value 'campaign1'
      entry.should_not be_nil
      stat = group.domain_log_stats.find_by_target_id entry.id
      stat.should_not be_nil
      stat.hits.should == 14
      stat.visits.should == 4

      entry = DomainLogGroupEntry.find_by_target_value 'campaign2'
      entry.should_not be_nil
      stat = group.domain_log_stats.find_by_target_id entry.id
      stat.should_not be_nil
      stat.hits.should == 8
      stat.visits.should == 4
    end

    it "should be able to get origin stats" do
      from = 1.day.ago
      duration = 1.day
      intervals = 1
      display = 'origin'

      assert_difference 'DomainLogGroup.count', 1 do
        assert_difference 'DomainLogStat.count', 3 do
          assert_difference 'DomainLogGroupEntry.count', 3 do
            @groups = DomainLogSession.affiliate(from, duration, intervals, :display => display)
          end
        end
      end

      group = @groups[0]
      group.target_type.should == 'DomainLogSession'
      group.target_id.should be_nil
      group.stat_type.should == "a::c::o::#{display}_traffic"
      group.started_at.should == from
      group.duration.should == duration
      group.expires_at.should be_nil

      entry = DomainLogGroupEntry.find_by_target_value 'origin1'
      entry.should_not be_nil
      stat = group.domain_log_stats.find_by_target_id entry.id
      stat.should_not be_nil
      stat.hits.should == 8
      stat.visits.should == 1

      entry = DomainLogGroupEntry.find_by_target_value 'origin2'
      entry.should_not be_nil
      stat = group.domain_log_stats.find_by_target_id entry.id
      stat.should_not be_nil
      stat.hits.should == 2
      stat.visits.should == 1

      entry = DomainLogGroupEntry.find_by_target_value 'origin3'
      entry.should_not be_nil
      stat = group.domain_log_stats.find_by_target_id entry.id
      stat.should_not be_nil
      stat.hits.should == 2
      stat.visits.should == 1
    end

    it "should be able to get specific campaign stats by affiliate" do
      from = 1.day.ago
      duration = 1.day
      intervals = 1
      display = 'campaign'

      assert_difference 'DomainLogGroup.count', 1 do
        assert_difference 'DomainLogStat.count', 2 do
          assert_difference 'DomainLogGroupEntry.count', 2 do
            @groups = DomainLogSession.affiliate(from, duration, intervals, :affiliate => 'affiliate1', :display => display)
          end
        end
      end

      group = @groups[0]
      group.target_type.should == 'DomainLogSession'
      group.target_id.should be_nil
      group.stat_type.should == "a:affiliate1:c::o::#{display}_traffic"
      group.started_at.should == from
      group.duration.should == duration
      group.expires_at.should be_nil

      entry = DomainLogGroupEntry.find_by_target_value 'campaign1'
      entry.should_not be_nil
      stat = group.domain_log_stats.find_by_target_id entry.id
      stat.should_not be_nil
      stat.hits.should == 8
      stat.visits.should == 1

      entry = DomainLogGroupEntry.find_by_target_value 'campaign2'
      entry.should_not be_nil
      stat = group.domain_log_stats.find_by_target_id entry.id
      stat.should_not be_nil
      stat.hits.should == 4
      stat.visits.should == 2

      assert_difference 'DomainLogGroup.count', 1 do
        assert_difference 'DomainLogStat.count', 1 do
          assert_difference 'DomainLogGroupEntry.count', 0 do
            @groups = DomainLogSession.affiliate(from, duration, intervals, :affiliate => 'affiliate2', :display => display)
          end
        end
      end

      group = @groups[0]
      group.target_type.should == 'DomainLogSession'
      group.target_id.should be_nil
      group.stat_type.should == "a:affiliate2:c::o::#{display}_traffic"
      group.started_at.should == from
      group.duration.should == duration
      group.expires_at.should be_nil

      entry = DomainLogGroupEntry.find_by_target_value 'campaign1'
      entry.should_not be_nil
      stat = group.domain_log_stats.find_by_target_id entry.id
      stat.should_not be_nil
      stat.hits.should == 4
      stat.visits.should == 2

      entry = DomainLogGroupEntry.find_by_target_value 'campaign2'
      entry.should_not be_nil
      stat = group.domain_log_stats.find_by_target_id entry.id
      stat.should be_nil

      assert_difference 'DomainLogGroup.count', 1 do
        assert_difference 'DomainLogStat.count', 2 do
          assert_difference 'DomainLogGroupEntry.count', 0 do
            @groups = DomainLogSession.affiliate(from, duration, intervals, :affiliate => 'affiliate3', :display => display)
          end
        end
      end

      group = @groups[0]
      group.target_type.should == 'DomainLogSession'
      group.target_id.should be_nil
      group.stat_type.should == "a:affiliate3:c::o::#{display}_traffic"
      group.started_at.should == from
      group.duration.should == duration
      group.expires_at.should be_nil

      entry = DomainLogGroupEntry.find_by_target_value 'campaign1'
      entry.should_not be_nil
      stat = group.domain_log_stats.find_by_target_id entry.id
      stat.should_not be_nil
      stat.hits.should == 2
      stat.visits.should == 1

      entry = DomainLogGroupEntry.find_by_target_value 'campaign2'
      entry.should_not be_nil
      stat = group.domain_log_stats.find_by_target_id entry.id
      stat.should_not be_nil
      stat.hits.should == 4
      stat.visits.should == 2
    end

    it "should be able to get specific origin stats by affiliate" do
      from = 1.day.ago
      duration = 1.day
      intervals = 1
      display = 'origin'

      assert_difference 'DomainLogGroup.count', 1 do
        assert_difference 'DomainLogStat.count', 1 do
          assert_difference 'DomainLogGroupEntry.count', 1 do
            @groups = DomainLogSession.affiliate(from, duration, intervals, :affiliate => 'affiliate1', :display => display)
          end
        end
      end

      group = @groups[0]
      group.target_type.should == 'DomainLogSession'
      group.target_id.should be_nil
      group.stat_type.should == "a:affiliate1:c::o::#{display}_traffic"
      group.started_at.should == from
      group.duration.should == duration
      group.expires_at.should be_nil

      entry = DomainLogGroupEntry.find_by_target_value 'origin1'
      entry.should_not be_nil
      stat = group.domain_log_stats.find_by_target_id entry.id
      stat.should_not be_nil
      stat.hits.should == 8
      stat.visits.should == 1

      assert_difference 'DomainLogGroup.count', 1 do
        assert_difference 'DomainLogStat.count', 0 do
          assert_difference 'DomainLogGroupEntry.count', 0 do
            @groups = DomainLogSession.affiliate(from, duration, intervals, :affiliate => 'affiliate2', :display => display)
          end
        end
      end

      group = @groups[0]
      group.target_type.should == 'DomainLogSession'
      group.target_id.should be_nil
      group.stat_type.should == "a:affiliate2:c::o::#{display}_traffic"
      group.started_at.should == from
      group.duration.should == duration
      group.expires_at.should be_nil

      group.domain_log_stats.count.should == 0

      assert_difference 'DomainLogGroup.count', 1 do
        assert_difference 'DomainLogStat.count', 2 do
          assert_difference 'DomainLogGroupEntry.count', 2 do
            @groups = DomainLogSession.affiliate(from, duration, intervals, :affiliate => 'affiliate3', :display => display)
          end
        end
      end

      group = @groups[0]
      group.target_type.should == 'DomainLogSession'
      group.target_id.should be_nil
      group.stat_type.should == "a:affiliate3:c::o::#{display}_traffic"
      group.started_at.should == from
      group.duration.should == duration
      group.expires_at.should be_nil

      entry = DomainLogGroupEntry.find_by_target_value 'origin2'
      entry.should_not be_nil
      stat = group.domain_log_stats.find_by_target_id entry.id
      stat.should_not be_nil
      stat.hits.should == 2
      stat.visits.should == 1

      entry = DomainLogGroupEntry.find_by_target_value 'origin3'
      entry.should_not be_nil
      stat = group.domain_log_stats.find_by_target_id entry.id
      stat.should_not be_nil
      stat.hits.should == 2
      stat.visits.should == 1
    end

    it "should be able to get specific affiliate stats by campaign" do
      from = 1.day.ago
      duration = 1.day
      intervals = 1
      display = 'affiliate'

      assert_difference 'DomainLogGroup.count', 1 do
        assert_difference 'DomainLogStat.count', 3 do
          assert_difference 'DomainLogGroupEntry.count', 3 do
            @groups = DomainLogSession.affiliate(from, duration, intervals, :campaign => 'campaign1', :display => display)
          end
        end
      end

      group = @groups[0]
      group.target_type.should == 'DomainLogSession'
      group.target_id.should be_nil
      group.stat_type.should == "a::c:campaign1:o::#{display}_traffic"
      group.started_at.should == from
      group.duration.should == duration
      group.expires_at.should be_nil

      entry = DomainLogGroupEntry.find_by_target_value 'affiliate1'
      entry.should_not be_nil
      stat = group.domain_log_stats.find_by_target_id entry.id
      stat.should_not be_nil
      stat.hits.should == 8
      stat.visits.should == 1

      entry = DomainLogGroupEntry.find_by_target_value 'affiliate2'
      entry.should_not be_nil
      stat = group.domain_log_stats.find_by_target_id entry.id
      stat.should_not be_nil
      stat.hits.should == 4
      stat.visits.should == 2

      entry = DomainLogGroupEntry.find_by_target_value 'affiliate3'
      entry.should_not be_nil
      stat = group.domain_log_stats.find_by_target_id entry.id
      stat.should_not be_nil
      stat.hits.should == 2
      stat.visits.should == 1

      assert_difference 'DomainLogGroup.count', 1 do
        assert_difference 'DomainLogStat.count', 2 do
          assert_difference 'DomainLogGroupEntry.count', 0 do
            @groups = DomainLogSession.affiliate(from, duration, intervals, :campaign => 'campaign2', :display => display)
          end
        end
      end

      group = @groups[0]
      group.target_type.should == 'DomainLogSession'
      group.target_id.should be_nil
      group.stat_type.should == "a::c:campaign2:o::#{display}_traffic"
      group.started_at.should == from
      group.duration.should == duration
      group.expires_at.should be_nil

      entry = DomainLogGroupEntry.find_by_target_value 'affiliate1'
      entry.should_not be_nil
      stat = group.domain_log_stats.find_by_target_id entry.id
      stat.should_not be_nil
      stat.hits.should == 4
      stat.visits.should == 2

      entry = DomainLogGroupEntry.find_by_target_value 'affiliate3'
      entry.should_not be_nil
      stat = group.domain_log_stats.find_by_target_id entry.id
      stat.should_not be_nil
      stat.hits.should == 4
      stat.visits.should == 2

      assert_difference 'DomainLogGroup.count', 1 do
        assert_difference 'DomainLogStat.count', 0 do
          assert_difference 'DomainLogGroupEntry.count', 0 do
            @groups = DomainLogSession.affiliate(from, duration, intervals, :campaign => 'campaign3', :display => display)
          end
        end
      end
    end

    it "should be able to get specific origin stats by affiliate and campaign" do
      from = 1.day.ago
      duration = 1.day
      intervals = 1
      display = 'origin'

      assert_difference 'DomainLogGroup.count', 1 do
        assert_difference 'DomainLogStat.count', 1 do
          assert_difference 'DomainLogGroupEntry.count', 1 do
            @groups = DomainLogSession.affiliate(from, duration, intervals, :affiliate => 'affiliate1', :campaign => 'campaign1', :display => display)
          end
        end
      end

      group = @groups[0]
      group.target_type.should == 'DomainLogSession'
      group.target_id.should be_nil
      group.stat_type.should == "a:affiliate1:c:campaign1:o::#{display}_traffic"
      group.started_at.should == from
      group.duration.should == duration
      group.expires_at.should be_nil

      entry = DomainLogGroupEntry.find_by_target_value 'origin1'
      entry.should_not be_nil
      stat = group.domain_log_stats.find_by_target_id entry.id
      stat.should_not be_nil
      stat.hits.should == 8
      stat.visits.should == 1

      assert_difference 'DomainLogGroup.count', 1 do
        assert_difference 'DomainLogStat.count', 2 do
          assert_difference 'DomainLogGroupEntry.count', 2 do
            @groups = DomainLogSession.affiliate(from, duration, intervals, :affiliate => 'affiliate3', :campaign => 'campaign2', :display => display)
          end
        end
      end

      group = @groups[0]
      group.target_type.should == 'DomainLogSession'
      group.target_id.should be_nil
      group.stat_type.should == "a:affiliate3:c:campaign2:o::#{display}_traffic"
      group.started_at.should == from
      group.duration.should == duration
      group.expires_at.should be_nil

      entry = DomainLogGroupEntry.find_by_target_value 'origin2'
      entry.should_not be_nil
      stat = group.domain_log_stats.find_by_target_id entry.id
      stat.should_not be_nil
      stat.hits.should == 2
      stat.visits.should == 1

      entry = DomainLogGroupEntry.find_by_target_value 'origin3'
      entry.should_not be_nil
      stat = group.domain_log_stats.find_by_target_id entry.id
      stat.should_not be_nil
      stat.hits.should == 2
      stat.visits.should == 1

      assert_difference 'DomainLogGroup.count', 1 do
        assert_difference 'DomainLogStat.count', 0 do
          assert_difference 'DomainLogGroupEntry.count', 0 do
            @groups = DomainLogSession.affiliate(from, duration, intervals, :affiliate => 'affiliate1', :campaign => 'campaign2', :display => display)
          end
        end
      end

      assert_difference 'DomainLogGroup.count', 1 do
        assert_difference 'DomainLogStat.count', 0 do
          assert_difference 'DomainLogGroupEntry.count', 0 do
            @groups = DomainLogSession.affiliate(from, duration, intervals, :affiliate => 'affiliate2', :campaign => 'campaign1', :display => display)
          end
        end
      end

      assert_difference 'DomainLogGroup.count', 1 do
        assert_difference 'DomainLogStat.count', 0 do
          assert_difference 'DomainLogGroupEntry.count', 0 do
            @groups = DomainLogSession.affiliate(from, duration, intervals, :affiliate => 'affiliate2', :campaign => 'campaign2', :display => display)
          end
        end
      end

      assert_difference 'DomainLogGroup.count', 1 do
        assert_difference 'DomainLogStat.count', 0 do
          assert_difference 'DomainLogGroupEntry.count', 0 do
            @groups = DomainLogSession.affiliate(from, duration, intervals, :affiliate => 'affiliate3', :campaign => 'campaign1', :display => display)
          end
        end
      end
    end
  end

  describe "Referrer Stats" do
    before do
      delete_all_stat_data

      create_session 3.hours.ago, 1, false

      @referrer1 = Factory(:domain_log_referrer, :referrer_domain => 'test.com', :referrer_path => '/home.html')
      create_session 4.hours.ago, 3, false, :domain_log_referrer_id => @referrer1.id

      @referrer2 = Factory(:domain_log_referrer, :referrer_domain => 'test.com', :referrer_path => '/test.html')
      create_session 4.hours.ago, 3, false, :domain_log_referrer_id => @referrer2.id
      create_session 4.hours.ago, 1, false, :domain_log_referrer_id => @referrer2.id
      create_session 4.hours.ago, 2, false, :domain_log_referrer_id => @referrer2.id

      @referrer3 = Factory(:domain_log_referrer, :referrer_domain => 'mytest.com')
      create_session 4.hours.ago, 1, false, :domain_log_referrer_id => @referrer3.id

      @referrer4 = Factory(:domain_log_referrer, :referrer_domain => 'mytest.com')
      create_session 4.hours.ago, 2, false, :domain_log_referrer_id => @referrer4.id

      create_session 4.hours.ago, 2, false, :domain_log_referrer_id => @referrer4.id, :ignore => true
      create_session 4.hours.ago, 2, false, :domain_log_referrer_id => @referrer4.id, :domain_log_source_id => nil
    end

    after do
      delete_all_stat_data
    end

    it "calculate basic traffic stats" do
      from = 1.day.ago
      duration = 1.day
      intervals = 1

      assert_difference 'DomainLogGroup.count', 1 do
        assert_difference 'DomainLogStat.count', 1 do
          DomainLogEntry.traffic(from, duration, intervals)
        end
      end

      stat = DomainLogStat.last
      stat.visits.should == 7
      stat.hits.should == 13
    end

    it "should calculate stats for referrers" do
      from = 1.day.ago
      duration = 1.day
      intervals = 1

      assert_difference 'DomainLogGroup.count', 1 do
        assert_difference 'DomainLogStat.count', 4 do
          assert_difference 'DomainLogGroupEntry.count', 0 do
            @groups = DomainLogReferrer.traffic(from, duration, intervals)
          end
        end
      end

      group = @groups[0]

      stat = group.domain_log_stats.find_by_target_id @referrer1.id
      stat.hits.should == 3
      stat.visits.should == 1

      stat = group.domain_log_stats.find_by_target_id @referrer2.id
      stat.hits.should == 6
      stat.visits.should == 3

      stat = group.domain_log_stats.find_by_target_id @referrer3.id
      stat.hits.should == 1
      stat.visits.should == 1

      stat = group.domain_log_stats.find_by_target_id @referrer4.id
      stat.hits.should == 2
      stat.visits.should == 1

      assert_difference 'DomainLogGroup.count', 0 do
        assert_difference 'DomainLogStat.count', 0 do
          @groups = DomainLogReferrer.traffic(from, duration, intervals, :target_id => @referrer1.id)
        end
      end

      group = @groups[0]

      stat = group.domain_log_stats.find_by_target_id @referrer1.id
      stat.hits.should == 3
      stat.visits.should == 1
    end

    it "should calculate stats for specific referrer domain" do
      from = 1.day.ago
      duration = 1.day
      intervals = 1

      assert_difference 'DomainLogGroup.count', 1 do
        assert_difference 'DomainLogStat.count', 2 do
          assert_difference 'DomainLogGroupEntry.count', 2 do
            @groups = DomainLogReferrer.traffic(from, duration, intervals, :domain => 'test.com')
          end
        end
      end

      group = @groups[0]

      entry = DomainLogGroupEntry.find_by_target_value @referrer1.referrer_path
      entry.should_not be_nil
      stat = group.domain_log_stats.find_by_target_id entry.id
      stat.hits.should == 3
      stat.visits.should == 1
      stat.target.target_value.should == '/home.html'

      entry = DomainLogGroupEntry.find_by_target_value @referrer2.referrer_path
      entry.should_not be_nil
      stat = group.domain_log_stats.find_by_target_id entry.id
      stat.hits.should == 6
      stat.visits.should == 3
      stat.target.target_value.should == '/test.html'
    end
  end

  describe "SiteNode Stats" do
    before do
      delete_all_stat_data

      @node1 = SiteVersion.default.root.push_subpage ''

      create_session 3.hours.ago, 1, false, :site_node_id => @node1.id
      create_session 3.hours.ago, 2, false, :site_node_id => @node1.id

      @node2 = SiteVersion.default.root.push_subpage '/test'

      create_session 3.hours.ago, 4, false, :site_node_id => @node2.id
      create_session 3.hours.ago, 1, false, :site_node_id => @node2.id

    end

    after do
      delete_all_stat_data
    end

    it "calculate basic traffic stats" do
      start_time = 1.day.ago

      assert_difference 'DomainLogGroup.count', 1 do
        assert_difference 'DomainLogStat.count', 1 do
          DomainLogGroup.stats('DomainLogEntry', start_time, 1.day, 1, :stat_type => 'traffic') do |from, duration|
            DomainLogEntry.between(from, from+duration).hits_n_visits(nil)
          end
        end
      end

      stat = DomainLogStat.last
      stat.visits.should == 4
      stat.hits.should == 8
    end

    it "should calculate site node traffic" do
      from = 1.day.ago
      duration = 1.day
      intervals = 1

      assert_difference 'DomainLogGroup.count', 1 do
        assert_difference 'DomainLogStat.count', 2 do
          @groups = SiteNode.traffic(from, duration, intervals)
        end
      end

      group = @groups[0]

      stat = group.domain_log_stats.find_by_target_id @node1.id
      stat.hits.should == 3
      stat.visits.should == 2

      stat = group.domain_log_stats.find_by_target_id @node2.id
      stat.hits.should == 5
      stat.visits.should == 2
    end      

    it "should calculate site node traffic" do
      from = 1.day.ago
      duration = 1.day
      intervals = 1

      assert_difference 'DomainLogGroup.count', 1 do
        assert_difference 'DomainLogStat.count', 1 do
          @groups = @node1.traffic(from, duration, intervals)
        end
      end

      group = @groups[0]

      stat = group.domain_log_stats.find_by_target_id @node1.id
      stat.hits.should == 3
      stat.visits.should == 2
    end      
  end
end
