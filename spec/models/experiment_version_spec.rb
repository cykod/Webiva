require File.dirname(__FILE__) + "/../spec_helper"

describe ExperimentVersion do

  reset_domain_tables :experiment, :experiment_version, :experiment_user, :site_node, :site_version, :page_revision, :page_paragraphs, :domain_files

  it "should require a name and a container" do
    exp = ExperimentVersion.new
    exp.should have(1).error_on(:language)
    exp.should have(1).error_on(:weight)
    exp.should have(1).error_on(:experiment_id)
  end

  it "should be able to create a version" do
    exp = ExperimentVersion.create :language => 'en', :revision => 0.01, :weight => 50, :experiment_id => 1
    exp.id.should_not be_nil
  end

  it "should not mark users as successful if experiment is over" do
    language = 'en'
    visitor = DomainLogVisitor.create :ip_address => '127.0.0.1'
    visitor.id.should_not be_nil

    home_page = SiteVersion.default.root.pages.find_by_title('')
    SiteVersion.default.root.push_subpage('') do |nd, rv|
      rv.title = "Home Page Version 1"
    end

    page_revision = nil
    SiteVersion.default.root.push_subpage('') do |nd, rv|
      page_revision = rv
      rv.revision = 0.02
      rv.title = "Home Page Version 2"
    end

    page_revision.reload
    page_revision.revision.should == 0.02

    SiteVersion.default.root.push_subpage('') do |nd, rv|
      rv.revision = 0.03
      rv.title = "Home Page Version 3"
    end

    home_page.page_revisions.count.should == 4

    @exp = Experiment.new :experiment_container => home_page, :language => 'en'
    assert_difference 'ExperimentVersion.count', 3 do
      assert_difference 'Experiment.count', 1 do
        @exp.update_attributes :name => 'Test', :versions => [{:revision => 0.01, :weight => 0}, {:revision => 0.02, :weight => 100}, {:revision => 0.03, :weight => 0}]
      end
    end

    home_page.is_running_an_experiment?.should be_false
    home_page.update_attribute :experiment_id, @exp.id

    home_page = SiteNode.find home_page.id
    home_page.is_running_an_experiment?.should be_false

    @exp.start!

    home_page = SiteNode.find home_page.id
    home_page.is_running_an_experiment?.should be_true

    assert_difference 'ExperimentUser.count', 0 do
      home_page.experiment_page_revision(visitor, 'es').should be_nil
      home_page.experiment_page_revision(visitor, 'fr').should be_nil
      home_page.experiment_page_revision(visitor, 'de').should be_nil
    end

    assert_difference 'ExperimentUser.count', 1 do
      @experiment_page_revision = home_page.experiment_page_revision(visitor, language)
    end

    @experiment_page_revision.should_not be_nil
    @experiment_page_revision.revision.should == 0.02
    @experiment_page_revision.id.should == page_revision.id

    live_revision = home_page.active_revision language
    live_revision.revision.should == 0.01
    live_revision.id.should_not == @experiment_page_revision.id

    home_page = SiteNode.find home_page.id
    assert_difference 'ExperimentUser.count', 0 do
      home_page.experiment_page_revision(visitor, language).id.should == @experiment_page_revision.id
    end

    @exp.end_experiment!

    home_page = SiteNode.find home_page.id
    home_page.is_running_an_experiment?.should be_false
    home_page.experiment_page_revision(visitor, language).should be_nil
  end
end
