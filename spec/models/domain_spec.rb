require File.dirname(__FILE__) + "/../spec_helper"

describe Domain do

  reset_system_tables :domains, :clients, :domain_databases

  before(:each) do
    @client = Client.find :first
  end

  it "should be a valid domain" do
    @client = Client.create :name => 'New Client'
    @domain = Domain.new
    @domain.valid?
    @domain.should have(2).errors_on(:name)
    @domain.should have(1).errors_on(:client_id)
    @domain = Domain.new :client_id => @client.id
    @domain.name = '_ape.com'
    @domain.should have(1).errors_on(:name)
    @domain.name = 'ape.com'
    @domain.valid?.should be_true
    @domain.name = 'my.ape.com'
    @domain.valid?.should be_true
    @domain.name = 'ape.c-om'
    @domain.should have(1).errors_on(:name)
    @domain.name = 'ape.com'
    @domain.domain_type = 'new_domain'
    @domain.valid?.should be_false
    @domain.should have(1).errors_on(:domain_type)
  end

  it "should be able to create a domain" do
    @client = Client.create :name => 'New Client'
    @domain = Domain.create :name => 'test-webiva.dev', :client_id => @client.id
    @domain.id.should_not be_nil
  end

  it "should make this domain the primary" do
    @client = Client.create :name => 'New Client'
    @db = @client.domain_databases.create :name => 'test_webiva_dev_100'
    @domain = @client.domains.create :name => 'test-webiva.dev', :database => @db.name
    @domain.id.should_not be_nil
    @domain.set_primary
    @domain.reload
    @domain.primary.should be_true
  end

  it "should create a domain database if max_file_storage is set" do
    @client = Client.create :name => 'New Client'

    # this would be for existing systems that were setup before domain_databases table existed
    assert_difference 'DomainDatabase.count', 1 do
      @domain = @client.domains.create :name => 'test-webiva.dev', :database => 'test_webiva_dev_100', :max_file_storage => 1
    end

    @domain.reload

    @db = DomainDatabase.find :last
    @db.id.should == @domain.domain_database_id
  end
end
