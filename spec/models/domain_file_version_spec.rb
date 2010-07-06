require File.dirname(__FILE__) + "/../spec_helper"

# Test added version support by DomainFileVersion
# This tests a bunch of functionality on DomainFile as well

describe DomainFileVersion do
  
  reset_domain_tables :domain_file, :domain_file_version, :domain_file_instance
  
  before(:each) do
    DomainFile.root_folder
    fdata = fixture_file_upload("files/rails.png",'image/jpeg')
    
    @df = DomainFile.create(:filename => fdata)
  end
  
  after(:each) do 
    @df.destroy # Make sure we get rid of the files in the system
  end

  it "should be able to archive a domain file, have it create the correct version file, and then archive" do

    File.exists?(@df.filename).should be_true
    @version = DomainFileVersion.archive(@df)
    
    @version.width.should == 50
    @version.height.should == 64
    
    File.exists?(@version.filename).should be_true # version file name should exist
    File.exists?(@df.filename).should be_false # but the original file shouldn't
    File.exists?(@df.filename(:icon)).should be_false # Make sure the thumbs are gone too
  
    @version.destroy
    File.exists?(@version.filename).should be_false
  end
  
  it "should be able to replace the file in a domain file and have it update the file and create a version" do
    fdata2 = fixture_file_upload("files/system_domains.gif","image/gif")
    
    old_filename = @df.filename
    File.exists?(@df.filename).should be_true # version file name should exist
    
    @df.filename = fdata2
    @df.save
    
    @df.filename.should_not == old_filename
    File.exists?(@df.filename).should be_true # version file name should exist
    @df.version_count.should == 1
    
    
    File.exists?(@df.versions[0].filename).should be_true # version file name should exist
    
    new_filename = @df.filename
    version_filename = @df.versions[0].filename
    
    @df.destroy
    
    File.exists?(new_filename).should be_false
    File.exists?(version_filename).should be_false
  end
  
 
  it "should be able to replace one domain file with another" do
    @df.save
    fdata2 = fixture_file_upload("files/system_domains.gif","image/gif")
    
    @df2 = DomainFile.create(:filename => fdata2)
    
    
    
    File.exists?(@df.filename).should be_true # Make sure the original is there
    File.exists?(@df2.filename).should be_true # Make sure the original is there
    @old_filename = @df.filename
    @df.replace(@df2)
    
    File.exists?(@old_filename).should be_false # We know this is false b/c rails.png and system_domains are different file names
    File.exists?(@df2.filename).should be_false # Replacement file should be destroyed
    
    File.exists?(@df.filename).should be_true # new version file name should exist
    @df.version_count.should == 1
    File.exists?(@df.versions[0].filename).should be_true # version file name should exist
    
    @df2.destroy
  end
  
  it "should be able to rename a file and have it create version and replace it" do
    
    old_filename = @df.filename
    File.exists?(@df.filename).should be_true # version file name should exist
    
    @df.rename('renamed_rails.png')
    
    @df.filename.should_not == old_filename
    File.exists?(old_filename).should be_false # old file shouldn't exist
    File.exists?(@df.filename).should be_true # version file name should exist
    @df.version_count.should == 1
    
    
    File.exists?(@df.versions[0].filename).should be_true # version file name should exist
    
    new_filename = @df.filename
    version_filename = @df.versions[0].filename
    
    @df.destroy
    
    File.exists?(new_filename).should be_false
    File.exists?(version_filename).should be_false  
  end
  
  it "should be able extract a revision" do
     @df.save
    fdata2 = fixture_file_upload("files/system_domains.gif","image/gif")
    
    @df2 = DomainFile.create(:filename => fdata2)
    
    File.exists?(@df.filename).should be_true # Make sure the original is there
    File.exists?(@df2.filename).should be_true # Make sure the original is there
    @old_filename = @df.filename
    @old_name = @df.name
    @df.replace(@df2)  
    
    @df.reload
    
    version = @df.versions[0]
  
    File.exists?(@df.filename).should be_true # new version file name should exist
    
    @hash = version.extract_file
    @file = DomainFile.find @hash[:domain_file_id]

    @file.name.should == @old_name # should match the old name
    
    @df.destroy
    @file.destroy
  
  end
  
    
  
end
