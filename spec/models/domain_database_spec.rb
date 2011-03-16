require File.dirname(__FILE__) + "/../spec_helper"

describe DomainDatabase do

  reset_system_tables :domains, :clients, :domain_databases

  it "should be a valid domain database" do
    @db = DomainDatabase.new
    @db.valid?
    @db.should have(1).errors_on(:client_id)
  end

  it "should be to create a domain database" do
    @client = Client.create :name => 'New Client'
    @db = DomainDatabase.create :name => 'webiva_001_test_dev', :client_id => @client.id
    @db.id.should_not be_nil

    @db = DomainDatabase.create :name => 'webiva_001_test_dev', :client_id => @client.id
    @db.id.should be_nil
  end

  it "should not allow an invalid max_file_storage" do
    @client = Client.create :name => 'New Client'
    @db = DomainDatabase.create :name => 'test_webiva_001_test_dev', :client_id => @client.id, :max_file_storage => @client.max_file_storage + 1
    @db.id.should be_nil
  end

  it "should set the options to the yml file if it exists" do
    database_file = "#{RAILS_ROOT}/config/sites/test_webiva_001_test_dev.yml"
    File.unlink(database_file) if File.exists?(database_file) # incase this test failed previously

    @client = Client.create :name => 'New Client'
    @db = DomainDatabase.create :name => 'test_webiva_001_test_dev', :client_id => @client.id
    @db.id.should_not be_nil
    @db.options.should be_nil

    output = {'production' => {'host' => 'localhost', 'username' => 'test', 'password' => ''}}
    File.open(database_file,"w") { |fd| fd.write(YAML.dump(output)) }
    @db.options.should_not be_nil
    @db.options['production']['host'].should == 'localhost'

    File.unlink database_file
    @db.reload
    @db.options['production']['host'].should == 'localhost'
  end

  it "should be able to get the first domain" do
    @client = Client.create :name => 'New Client'
    @db = @client.domain_databases.create :name => 'test_webiva_001_test_dev'
    @db.id.should_not be_nil
    @db.first_domain.should be_nil
    @db.domain_name.should == 'test_webiva_001_test_dev'

    @domain = @client.domains.create :name => 'test-webiva.dev', :domain_database_id => @db.id
    @domain.id.should_not be_nil

    @db.reload
    @db.first_domain.id.should == @domain.id
    @db.domain_name.should == 'test-webiva.dev'
  end

  it "should be clearing the domain info cache after saving" do
    @client = Client.create :name => 'New Client'
    @db = @client.domain_databases.create :name => 'test_webiva_001_test_dev'
    @db.id.should_not be_nil
    @domain = @client.domains.create :name => 'test-webiva.dev', :domain_database_id => @db.id
    @domain.id.should_not be_nil

    @db.reload

    DataCache.should_receive(:set_domain_info).with('test-webiva.dev', nil)
    @db.update_attribute(:max_file_storage, 2)
  end
end
