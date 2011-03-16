require File.dirname(__FILE__) + "/../../spec_helper"

describe ModelExtension::EndUserImportExtension do

  reset_domain_tables :end_user, :end_user_cache, :end_user_action, :end_user_tag, :end_user_address, :domain_file, :tag, :tag_note

  before(:each) do
    fdata = fixture_file_upload("files/import.csv",'text/csv')
    @df = DomainFile.create(:filename => fdata)

    @data = {
      :actions => {},
      :create => {},
      :matches => {
        "0" => "email",
        "1" => "name",
        "2" => "language",
        "3" => "gender",
        "4" => "tags",
        "5" => "salutation",
        "6" => "introduction",
        "7" => "suffix",
        "8" => "referrer",
        "9" => "lead_source",
        "10" => "username",
        "11" => "password",
        "12" => "cell_phone",
        "13" => "remove_tags",
        "14" => "dob",
        "15" => "vip_number",
        "16" => "work_company",
        "17" => "work_phone",
        "18" => "work_fax",
        "19" => "work_address",
        "20" => "work_address_2",
        "21" => "work_city",
        "22" => "work_state",
        "23" => "work_zip",
        "24" => "work_country",
        "25" => "home_phone",
        "26" => "home_fax",
        "27" => "home_address",
        "28" => "home_address_2",
        "29" => "home_city",
        "30" => "home_state",
        "31" => "home_zip",
        "32" => "home_country",
        "33" => "billing_phone",
        "34" => "billing_fax",
        "35" => "billing_address",
        "36" => "billing_address_2",
        "37" => "billing_city",
        "38" => "billing_state",
        "39" => "billing_zip",
        "40" => "billing_country"
      }
    }

    @data[:matches].each { |k,v| @data[:actions][k] = "m" }

    # ignore fields
    @data[:actions]["4"] = "i"
    @data[:actions]["13"] = "i"
    @data[:actions]["15"] = "i"

    @options = {
      :deliminator =>",",
      :options => {:user_class_id => "4", :user_list_name => "", :all_tags => "", :user_list => "", :import_mode => "normal", :user_options => [""], :create_tags => ""},
      :import => true
    }
  end

  after(:each) do
    @df.destroy if @df
  end

  it "should be able to import users" do
    user = EndUser.push_target('test2@test.dev', :first_name => 'Change1', :last_name => 'Me1', :user_level => 3, :source => 'site')
    user.id.should_not be_nil

    @options[:options][:all_tags] = 'imported'
    @options[:options][:create_tags] = 'created'
    @options[:options][:user_list] = 'create'
    @options[:options][:user_list_name] = 'New List'
    @options[:options][:user_options] = ['vip']
    @data[:actions]["4"] = "m"

    assert_difference 'UserSegment.count', 1 do
      assert_difference 'EndUserTag.count', 29 do
        assert_difference 'EndUserAddress.count', 30 do
          assert_difference 'EndUser.count', 9 do
            EndUser.import_csv @df.filename, @data, @options
          end
        end
      end
    end

    user.reload
    user.first_name.should == 'First2'
    user.last_name.should == 'Last2'
    user.tags_array.should == ['Imported', 'Tester']
    user.vip_number.should_not be_nil
    user.user_level.should == 3
    user.source.should == 'site'

    user = EndUser.find_by_email 'test1@test.dev'
    user.tags_array.should == ['Imported', 'Created', 'Tester']
    user.user_level.should == 1
    user.source.should == 'import'

    user_list = UserSegment.last
    user_list.last_count.should == 10
  end

  it "should be able to update only" do
    user = EndUser.push_target('test2@test.dev', :first_name => 'Change1', :last_name => 'Me1')
    user.id.should_not be_nil
    user.tag ['Rtag']

    @options[:options][:import_mode] = 'update'
    @data[:actions]["4"] = "m"
    @data[:actions]["13"] = "m"

    # adding and removing a tag
    assert_difference 'EndUserTag.count', 0 do
      assert_difference 'EndUser.count', 0 do
        EndUser.import_csv @df.filename, @data, @options
      end
    end

    user = EndUser.find_by_email 'test2@test.dev'
    user.first_name.should == 'First2'
    user.last_name.should == 'Last2'
    user.vip_number.should be_nil
    user.tags_array.should == ['Tester']

    user = EndUser.find_by_email 'test1@test.dev'
    user.should be_nil
  end

  it "should be able to create only" do
    user = EndUser.push_target('test2@test.dev', :first_name => 'Change1', :last_name => 'Me1')
    user.id.should_not be_nil

    @options[:options][:import_mode] = 'create'
    @data[:actions]["15"] = "m" # import vip number

    assert_difference 'EndUser.count', 9 do
      EndUser.import_csv @df.filename, @data, @options
    end

    user.reload
    user.first_name.should == 'Change1'
    user.last_name.should == 'Me1'

    user = EndUser.find_by_email 'test1@test.dev'
    user.should_not be_nil
    user.vip_number.should == '1VIP'
  end
end
