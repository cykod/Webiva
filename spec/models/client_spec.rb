require File.dirname(__FILE__) + "/../spec_helper"

describe Client do

  reset_system_tables :clients

  it "should be a valid client" do
    @client = Client.new
    @client.should have(1).errors_on(:name)
    @client.should have(0).errors_on(:domain_limit)
    @client.should have(0).errors_on(:max_client_users)
    @client.should have(0).errors_on(:max_file_storage)
  end

  it "should be able to create a new client with just a name" do
    @client = Client.create :name => 'New Client'
    @client.id.should_not be_nil

    @client.num_databases.should == 0
    @client.domain_limit.should > 0
    @client.can_add_database?.should be_true
    @client.num_client_users.should == 0
    @client.max_client_users.should > 0
    @client.available_client_users.should == @client.max_client_users
    @client.used_file_storage.should == 0
    @client.max_file_storage.should > 0
    @client.available_file_storage.should == @client.max_file_storage
  end

  it "can not create a client with the same name" do
    @client = Client.create :name => 'New Client'
    @client.id.should_not be_nil

    @client = Client.create :name => 'New Client'
    @client.id.should be_nil
  end
end
