require File.dirname(__FILE__) + "/../spec_helper"
require 'fakeweb'

describe DomainFile::LocalProcessor do

  reset_domain_tables :domain_file, :domain_file_version
  reset_system_tables :server

  def fakeweb_df_transmit_domain_file(file)
    fixture = fixture_file_upload("files/#{file.name}", file.mime_type)
    FakeWeb.register_uri(:get, "http://#{file.server.hostname}/website/transmit_file/file/#{DomainModel.active_domain_id}/#{file.id}/#{file.server_hash}", :body => fixture.read)
  end

  def fakeweb_df_transmit_domain_file_version(version)
    fixture = fixture_file_upload("files/#{version.domain_file.name}", version.domain_file.mime_type)
    FakeWeb.register_uri(:get, "http://#{version.server.hostname}/website/transmit_file/file_version/#{DomainModel.active_domain_id}/#{version.domain_file.id}/#{version.domain_file.server_hash}/#{version.id}", :body => fixture.read)
  end

  def fakeweb_df_delete_domain_file(server, file)
    key = DomainFile::LocalProcessor.set_directories_to_delete(file.storage_directory)
    FakeWeb.register_uri(:get, "http://#{server.hostname}/website/transmit_file/delete/#{DomainModel.active_domain_id}/#{key}", :body => '')
  end

  before(:each) do
    FakeWeb.clean_registry
    FakeWeb.allow_net_connect = false

    @server1 = Server.create :hostname => 'server1.test.dev', :web => true, :workling => true
    @server2 = Server.create :hostname => 'server2.test.dev', :workling => true
    @server3 = Server.create :hostname => 'server3.test.dev', :web => true

    fdata = fixture_file_upload("files/rails.png",'image/png')
    @file1 = DomainFile.create(:filename => fdata)
    @file1.update_attribute(:server_id, @server1.id)

    fdata = fixture_file_upload("files/test.txt",'text/plain')
    @file2 = DomainFile.create(:filename => fdata)
    @file2.update_attribute(:server_id, @server2.id)

    fdata = fixture_file_upload("files/system_domains.gif",'image/gif')
    @file3 = DomainFile.create(:filename => fdata, :private => true)
    @file3.update_attribute(:server_id, @server3.id)
  end

  after(:each) do
    if @file1
      @file1.server_hash = nil
      @file1.destroy
    end

    if @file2
      @file2.server_hash = nil
      @file2.destroy
    end

    if @file3
      @file3.server_hash = nil
      @file3.destroy
    end
  end

  it "should be able to return the local processor" do
    @processor = @file1.processor_handler
    @processor.should_not be_nil
    @processor.class.should == DomainFile::LocalProcessor
    @processor.copy_remote!.should be_true
    @processor.revision_support.should be_true
  end

  it "should not copy a file locally if it is the same server" do
    @file1.server_id.should == @server1.id
    @file2.server_id.should == @server2.id

    Server.should_receive(:server_id).any_number_of_times.and_return(@server1.id)

    @processor = @file1.processor_handler
    @processor.copy_local!.should be_true
  end

  it "should be able to copy a file locally" do
    Server.should_receive(:server_id).any_number_of_times.and_return(@server1.id)

    fakeweb_df_transmit_domain_file @file2

    File.unlink @file2.local_filename
    File.exists?(@file2.local_filename).should be_false

    @processor = @file2.processor_handler
    @processor.copy_local!.should be_true

    File.exists?(@file2.local_filename).should be_true
  end

  it "should be able to copy a file locally" do
    Server.should_receive(:server_id).any_number_of_times.and_return(@server1.id)

    fakeweb_df_transmit_domain_file @file2

    File.unlink @file2.local_filename
    File.exists?(@file2.local_filename).should be_false

    @file2.filename

    File.exists?(@file2.local_filename).should be_true
  end

  it "should delete remote copies" do
    Server.should_receive(:server_id).any_number_of_times.and_return(@server1.id)
    DomainModel.should_receive(:generate_hash).any_number_of_times.and_return('XXXXXXXXX')

    fakeweb_df_delete_domain_file @server2, @file2
    fakeweb_df_delete_domain_file @server3, @file2

    @processor = @file2.processor_handler
    @processor.destroy_remote!.should be_true
  end

  it "should delete remote copies" do
    Server.should_receive(:server_id).any_number_of_times.and_return(@server1.id)
    DomainModel.should_receive(:generate_hash).any_number_of_times.and_return('XXXXXXXXX')

    fakeweb_df_delete_domain_file @server2, @file2
    fakeweb_df_delete_domain_file @server3, @file2

    @file2.destroy

    File.exists?(@file2.local_filename).should be_false

    @file2 = nil
  end

  it "should be able create a private file" do
    Server.should_receive(:server_id).any_number_of_times.and_return(@server1.id)
    DomainModel.should_receive(:generate_hash).any_number_of_times.and_return('XXXXXXXXX')

    fakeweb_df_transmit_domain_file @file2

    fakeweb_df_delete_domain_file @server2, @file2
    fakeweb_df_delete_domain_file @server3, @file2

    File.unlink @file2.local_filename
    File.exists?(@file2.local_filename).should be_false

    @processor = @file2.processor_handler
    @processor.update_private! true

    File.exists?(@file2.local_filename).should be_true

    @file2.private.should be_true
    @file2.server_id.should == @server1.id
  end

  it "should be able create a public file" do
    Server.should_receive(:server_id).any_number_of_times.and_return(@server1.id)
    DomainModel.should_receive(:generate_hash).any_number_of_times.and_return('XXXXXXXXX')

    fakeweb_df_transmit_domain_file @file3

    fakeweb_df_delete_domain_file @server2, @file3
    fakeweb_df_delete_domain_file @server3, @file3

    File.unlink @file3.local_filename
    File.exists?(@file3.local_filename).should be_false

    @processor = @file3.processor_handler
    @processor.update_private! false

    File.exists?(@file3.local_filename).should be_true

    @file3.private.should be_false
    @file3.server_id.should == @server1.id
  end

  it "should be able to copy a remote version" do
    Server.should_receive(:server_id).any_number_of_times.and_return(@server1.id)
    DomainModel.should_receive(:generate_hash).any_number_of_times.and_return('XXXXXXXXX')

    fakeweb_df_transmit_domain_file @file3

    fakeweb_df_delete_domain_file @server2, @file3
    fakeweb_df_delete_domain_file @server3, @file3

    File.unlink @file3.local_filename
    File.exists?(@file3.local_filename).should be_false

    assert_difference 'DomainFileVersion.count', 1 do
      @file2.replace @file3
      @file3 = nil
    end

    @file2.version_count.should == 1

    @version = DomainFileVersion.find :last
    @version.domain_file_id.should == @file2.id

    File.unlink @version.filename
    File.exists?(@version.filename).should be_false

    @version.update_attribute :server_id, @server3.id
    fakeweb_df_transmit_domain_file_version @version
    @processor = @file2.processor_handler
    @processor.copy_version_local!(@version).should be_true

    File.exists?(@version.filename).should be_true
  end

  it "should be able to deleta a remote version" do
    Server.should_receive(:server_id).any_number_of_times.and_return(@server1.id)
    DomainModel.should_receive(:generate_hash).any_number_of_times.and_return('XXXXXXXXX')

    fakeweb_df_transmit_domain_file @file3

    fakeweb_df_delete_domain_file @server2, @file3
    fakeweb_df_delete_domain_file @server3, @file3

    File.unlink @file3.local_filename
    File.exists?(@file3.local_filename).should be_false

    assert_difference 'DomainFileVersion.count', 1 do
      @file2.replace @file3
      @file3 = nil
    end

    @file2.version_count.should == 1

    @version = DomainFileVersion.find :last
    @version.domain_file_id.should == @file2.id

    File.unlink @version.filename
    File.exists?(@version.filename).should be_false

    @version.update_attribute :server_id, @server3.id
    fakeweb_df_transmit_domain_file_version @version
    @processor = @file2.processor_handler
    @processor.copy_version_local!(@version).should be_true

    File.exists?(@version.filename).should be_true

    FakeWeb.clean_registry
    fakeweb_df_delete_domain_file @server2, @version
    fakeweb_df_delete_domain_file @server3, @version

    @version.destroy

    File.exists?(@version.filename).should be_false
  end

  it "should be able to extract a remote version" do
    Server.should_receive(:server_id).any_number_of_times.and_return(@server1.id)
    DomainModel.should_receive(:generate_hash).any_number_of_times.and_return('XXXXXXXXX')

    fakeweb_df_transmit_domain_file @file3

    fakeweb_df_delete_domain_file @server2, @file3
    fakeweb_df_delete_domain_file @server3, @file3

    File.unlink @file3.local_filename
    File.exists?(@file3.local_filename).should be_false

    assert_difference 'DomainFileVersion.count', 1 do
      @file2.replace @file3
      @file3 = nil
    end

    @file2.version_count.should == 1

    @version = DomainFileVersion.find :last
    @version.domain_file_id.should == @file2.id

    File.unlink @version.filename
    File.exists?(@version.filename).should be_false

    @version.update_attribute :server_id, @server3.id
    fakeweb_df_transmit_domain_file_version @version

    assert_difference 'DomainFile.count', 1 do
      @file4 = DomainFile.find @version.extract_file[:domain_file_id]
    end

    File.exists?(@version.filename).should be_true
    File.exists?(@file4.local_filename).should be_true

    @file4.name.should == 'test.txt'

    @file4.server_hash = nil
    @file4.destroy
  end
end
