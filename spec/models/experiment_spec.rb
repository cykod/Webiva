require File.dirname(__FILE__) + "/../spec_helper"

describe Experiment do

  reset_domain_tables :experiment, :experiment_version, :experiment_user, :site_node, :site_version, :domain_log_visitor, :domain_log_session, :page_revision, :page_paragraph, :triggered_action

  def get_session
    return @session if @session
    visitor = DomainLogVisitor.create :ip_address => '127.0.0.1'
    session = DomainLogSession.create :ip_address => '127.0.0.1'
    @session = {:cms_language => 'en', :domain_log_session => {:id => session.id, :end_user_id => nil}, :domain_log_visitor => {:id => visitor.id, :end_user_id => nil, :loc => nil}}
  end

  it "should require a name and a container" do
    exp = Experiment.new
    exp.should have(1).error_on(:name)
    exp.should have(1).error_on(:experiment_container_type)
    exp.should have(1).error_on(:experiment_container_id)
  end

  it "should be able to create an experiment" do
    home_page = SiteVersion.default.root.pages.find_by_title('')
    assert_difference 'Experiment.count', 1 do
      Experiment.create :experiment_container => home_page, :name => 'Test'
    end
  end

  it "should be able to create an experiment with multiple versions" do
    home_page = SiteVersion.default.root.pages.find_by_title('')
    @exp = Experiment.new :experiment_container => home_page, :language => 'en'
    assert_difference 'ExperimentVersion.count', 2 do
      assert_difference 'Experiment.count', 1 do
        @exp.update_attributes :name => 'Test', :versions => [{:revision => '0.01', :weight => 50}, {:revision => '0.02', :weight => 50}]
      end
    end
    
    @exp = Experiment.find @exp.id
    @exp.experiment_container.should == home_page
  end

  it "should not be able to create an experiment with multiple versions when weights are incorrect" do
    home_page = SiteVersion.default.root.pages.find_by_title('')
    @exp = Experiment.new :experiment_container => home_page, :language => 'en'
    assert_difference 'ExperimentVersion.count', 0 do
      assert_difference 'Experiment.count', 0 do
        @exp.update_attributes :name => 'Test', :versions => [{:revision => '0.01', :weight => 0}, {:revision => '0.02', :weight => 50}]
      end
    end
  end

  it "should be able to create multiple versions in different languages" do
    home_page = SiteVersion.default.root.pages.find_by_title('')
    @exp = Experiment.new :experiment_container => home_page, :language => 'en'
    assert_difference 'ExperimentVersion.count', 2 do
      assert_difference 'Experiment.count', 1 do
        @exp.update_attributes :name => 'Test', :versions => [{:revision => '0.01', :weight => 50}, {:revision => '0.02', :weight => 50}]
      end
    end

    @exp.reload
    @exp.language = 'es'

    assert_difference 'ExperimentVersion.count', 2 do
      @exp.update_attributes :versions => [{:revision => '0.01', :weight => 50}, {:revision => '0.02', :weight => 50}]
    end

    @exp.reload
    @exp.experiment_versions.count.should == 4
  end

  it "should be able to remove versions if the experiment is not running" do
    home_page = SiteVersion.default.root.pages.find_by_title('')
    @exp = Experiment.new :experiment_container => home_page, :language => 'en'
    assert_difference 'ExperimentVersion.count', 3 do
      assert_difference 'Experiment.count', 1 do
        @exp.update_attributes :name => 'Test', :versions => [{:revision => '0.01', :weight => 34}, {:revision => '0.02', :weight => 33}, {:revision => '0.03', :weight => 33}]
      end
    end

    @exp.reload
    @exp.experiment_versions.count.should == 3
    @ver1 = @exp.versions[0]
    @ver2 = @exp.versions[1]
    @ver1.weight.should == 34
    @ver2.weight.should == 33

    assert_difference 'ExperimentVersion.count', -1 do
      @exp.update_attributes :versions => [{:id => @ver1.id, :weight => 70}, {:id => @ver2.id, :weight => 30}]
    end

    @exp.reload
    @exp.experiment_versions.count.should == 2
    @ver1.reload
    @ver1.weight.should == 70
    @ver2.reload
    @ver2.weight.should == 30

    @exp.end_experiment!
    @exp.is_running?.should be_false

    @exp.restart! nil, :reset => true
    @exp.is_running?.should be_true
  end

  it "should not be able to remove versions if the experiment is running" do
    home_page = SiteVersion.default.root.pages.find_by_title('')
    @exp = Experiment.new :experiment_container => home_page, :language => 'en'
    assert_difference 'ExperimentVersion.count', 3 do
      assert_difference 'Experiment.count', 1 do
        @exp.update_attributes :name => 'Test', :versions => [{:revision => '0.01', :weight => 34}, {:revision => '0.02', :weight => 33}, {:revision => '0.03', :weight => 33}]
      end
    end

    @exp.reload
    @ver1 = @exp.versions[0]
    @ver2 = @exp.versions[1]

    @exp.start!
    @exp.is_running?.should be_true

    assert_difference 'ExperimentVersion.count', 0 do
      @exp.update_attributes :versions => [{:id => @ver1.id, :weight => 50}, {:id => @ver2.id, :weight => 50}]
    end

    @exp.reload
    @exp.experiment_versions.count.should == 3
    @ver1.reload
    @ver1.weight.should == 34
    @ver2.reload
    @ver2.weight.should == 33

    @exp.end_experiment!
    @exp.is_running?.should be_false

    @exp.restart!
    @exp.is_running?.should be_true
  end

  it "should be able to determine wether or not the experiment is running" do
    home_page = SiteVersion.default.root.pages.find_by_title('')
    @exp = Experiment.new :experiment_container => home_page, :language => 'en'
    assert_difference 'ExperimentVersion.count', 3 do
      assert_difference 'Experiment.count', 1 do
        @exp.update_attributes :name => 'Test', :versions => [{:revision => '0.01', :weight => 34}, {:revision => '0.02', :weight => 33}, {:revision => '0.03', :weight => 33}]
      end
    end

    @exp.start! 5.minutes.since
    @exp.is_running?.should be_false

    @exp.start! 5.minutes.ago
    @exp.is_running?.should be_true

    @exp.update_attribute :ended_at, 1.minutes.since
    @exp.is_running?.should be_true

    @exp.update_attribute :ended_at, 1.minutes.ago
    @exp.is_running?.should be_false

    @exp.update_attribute :ended_at, nil
    @exp.is_running?.should be_true

    @exp.update_attribute :started_at, nil
    @exp.is_running?.should be_false
  end

  it "should be able to pick a version for a visitor" do
    language = 'en'

    home_page = SiteVersion.default.root.pages.find_by_title('')
    @exp = Experiment.new :experiment_container => home_page, :language => 'en'
    assert_difference 'ExperimentVersion.count', 3 do
      assert_difference 'Experiment.count', 1 do
        @exp.update_attributes :name => 'Test', :versions => [{:revision => '0.01', :weight => 34}, {:revision => '0.02', :weight => 33}, {:revision => '0.03', :weight => 33}]
      end
    end

    @exp.start!

    assert_difference 'ExperimentUser.count', 1 do
      @version = @exp.get_version(get_session)
    end

    @version.should_not be_nil

    @user = @exp.get_user(get_session)
    @user.experiment_version_id.should == @version.id

    @user.success.should be_false

    assert_difference 'ExperimentUser.count', 0 do
      @version2 = @exp.get_version(get_session)
    end

    @version2.should_not be_nil
    @version2.id.should == @version.id

    language = 'es'

    assert_difference 'ExperimentUser.count', 0 do
      @version = @exp.get_version(get_session)
    end

    @visitor.should be_nil
  end

  it "should be able to mark an experiment as successful" do
    language = 'en'

    home_page = SiteVersion.default.root.pages.find_by_title('')
    @exp = Experiment.new :experiment_container => home_page, :language => 'en'
    assert_difference 'ExperimentVersion.count', 3 do
      assert_difference 'Experiment.count', 1 do
        @exp.update_attributes :name => 'Test', :versions => [{:revision => '0.01', :weight => 34}, {:revision => '0.02', :weight => 33}, {:revision => '0.03', :weight => 33}]
      end
    end

    @exp.start!

    assert_difference 'ExperimentUser.count', 1 do
      @version = @exp.get_version(get_session)
    end

    @version.should_not be_nil

    @user = @exp.get_user(get_session)
    @user.experiment_version_id.should == @version.id

    @user.success.should be_false

    Experiment.success! @exp.id, get_session

    @user.reload
    @user.success.should be_true
  end

  it "should not return a version unless the experiment has started" do
    language = 'en'

    home_page = SiteVersion.default.root.pages.find_by_title('')
    @exp = Experiment.new :experiment_container => home_page, :language => 'en'
    assert_difference 'ExperimentVersion.count', 3 do
      assert_difference 'Experiment.count', 1 do
        @exp.update_attributes :name => 'Test', :versions => [{:revision => '0.01', :weight => 34}, {:revision => '0.02', :weight => 33}, {:revision => '0.03', :weight => 33}]
      end
    end

    assert_difference 'ExperimentUser.count', 0 do
      @version = @exp.get_version(get_session)
    end

    @version.should be_nil
  end

  it "should not mark users as successful if experiment is over" do
    language = 'en'

    home_page = SiteVersion.default.root.pages.find_by_title('')
    @exp = Experiment.new :experiment_container => home_page, :language => 'en'
    assert_difference 'ExperimentVersion.count', 3 do
      assert_difference 'Experiment.count', 1 do
        @exp.update_attributes :name => 'Test', :versions => [{:revision => '0.01', :weight => 34}, {:revision => '0.02', :weight => 33}, {:revision => '0.03', :weight => 33}]
      end
    end

    @exp.start!

    assert_difference 'ExperimentUser.count', 1 do
      @version = @exp.get_version(get_session)
    end

    @version.should_not be_nil

    @user = @exp.get_user(get_session)
    @user.experiment_version_id.should == @version.id

    @user.success.should be_false

    @exp.end_experiment!

    Experiment.success! @exp.id, get_session

    @user.reload
    @user.success.should be_false
  end

  it "should be able to auto populate weights" do
    home_page = SiteVersion.default.root.pages.find_by_title('')
    @exp = Experiment.new :experiment_container => home_page, :language => 'en'
    assert_difference 'ExperimentVersion.count', 3 do
      assert_difference 'Experiment.count', 1 do
        @exp.update_attributes :name => 'Test', :versions => [{:revision => '0.01', :weight => ''}, {:revision => '0.02', :weight => ''}, {:revision => '0.03', :weight => ''}]
      end
    end

    @exp.total_weight.should == 100
    @exp.versions[0].weight.should == 34
    @exp.versions[1].weight.should == 33
    @exp.versions[2].weight.should == 33
  end

  describe "Conversion Page" do
    it "should added the experiment paragraph to the conversion page" do
      @conversion_page = SiteVersion.default.root.push_subpage('conversion')
      home_page = SiteVersion.default.root.pages.find_by_title('')
      @exp = Experiment.new :experiment_container => home_page, :language => 'en', :conversion_site_node => @conversion_page
      assert_difference 'ExperimentVersion.count', 3 do
        assert_difference 'Experiment.count', 1 do
          assert_difference 'PageParagraph.count', 1 do
            @exp.update_attributes :name => 'Test', :versions => [{:revision => '0.01', :weight => ''}, {:revision => '0.02', :weight => ''}, {:revision => '0.03', :weight => ''}]
          end
        end
      end
      
      assert_difference 'TriggeredAction.count', 0 do
        assert_difference 'PageParagraph.count', -1 do
          @exp.end_experiment!
          @exp.save
        end
      end
    end

    it "should added the experiment paragraph to the conversion page" do
      home_page = SiteVersion.default.root.pages.find_by_title('')
      home_page.new_revision { |rv| rv.revision = 0.02 }
      home_page.new_revision { |rv| rv.revision = 0.03 }
      @exp = Experiment.new :experiment_container => home_page, :language => 'en', :conversion_site_node => home_page, :webform_conversion => false
      assert_difference 'ExperimentVersion.count', 3 do
        assert_difference 'Experiment.count', 1 do
          assert_difference 'PageParagraph.count', 3 do
            @exp.update_attributes :name => 'Test', :versions => [{:revision => '0.01', :weight => ''}, {:revision => '0.02', :weight => ''}, {:revision => '0.03', :weight => ''}]
          end
        end
      end      

      assert_difference 'TriggeredAction.count', 0 do
        assert_difference 'PageParagraph.count', -3 do
          @exp.end_experiment!
          @exp.save
        end
      end
    end

    it "should added the experiment paragraph to the conversion page and setup the webform triggers" do
      home_page = SiteVersion.default.root.pages.find_by_title('')
      home_page.live_revisions.first.push_paragraph '/webform/page', 'form'
      home_page.new_revision { |rv| rv.revision = 0.02; rv.push_paragraph '/webform/page', 'form' }
      home_page.new_revision { |rv| rv.revision = 0.03; rv.push_paragraph '/webform/page', 'form' }
      @exp = Experiment.new :experiment_container => home_page, :language => 'en', :conversion_site_node => home_page, :webform_conversion => true
      assert_difference 'ExperimentVersion.count', 3 do
        assert_difference 'Experiment.count', 1 do
          assert_difference 'PageParagraph.count', 3 do
            assert_difference 'TriggeredAction.count', 3 do
              @exp.update_attributes :name => 'Test', :versions => [{:revision => '0.01', :weight => ''}, {:revision => '0.02', :weight => ''}, {:revision => '0.03', :weight => ''}]
            end
          end
        end
      end

      assert_difference 'TriggeredAction.count', -3 do
        assert_difference 'PageParagraph.count', -3 do
          @exp.end_experiment!
          @exp.save
        end
      end
    end
  end
end
