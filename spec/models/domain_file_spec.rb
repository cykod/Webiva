require File.dirname(__FILE__) + "/../spec_helper"

describe DomainFile do

  reset_domain_tables :domain_file, :domain_file_version
  
  before(:each) do
    fdata = fixture_file_upload("files/rails.png",'image/png')
    
    @df = DomainFile.new(:filename => fdata)
  end
  
  after(:each) do 
    @df.destroy # Make sure we get rid of the files in the system
  end
  
  it "should save it somewhere below the root folder" do
    @df.save
    
    @df.parent_id.should_not be_nil
  end

  it "should be able to upload a file, import it correctly, and destroy it afterwards" do 
    @df.save
    @df.prefix.should_not be_blank
    @df.name.should == 'rails.png'
    @df.mime_type.should == 'image/png'
    filename = @df.filename
    File.exists?(@df.filename).should be_true
    
    @df.width.should == 50
    @df.height.should == 64
    @df.file_size.should == 1787 
    
    @df.destroy
    File.exists?(filename).should be_false
  end
  
  it "should be able to read a file locally and import it correctly" do
    File.open("#{RAILS_ROOT}/spec/fixtures/files/rails.png") do |f|
      @df.filename = f
      @df.save
    end

    filename = @df.filename
    File.exists?(@df.filename).should be_true

    @df.name.should == 'rails.png'
    @df.width.should == 50
    @df.height.should == 64
    @df.file_size.should == 1787 
  end
  
  it "should generate all the default thumbnails on upload" do
    @df.save
    @df.file_type.should == 'img'
    
    File.exists?(@df.filename).should be_true
    File.exists?(@df.filename(:icon)).should be_true
    File.exists?(@df.filename(:thumb)).should be_true
    File.exists?(@df.filename(:preview)).should be_true
    File.exists?(@df.filename(:small)).should be_true
  end
  
  it "should not save an invalid file" do
    @df.filename = nil
    @df.should_not be_valid
  end
  
  it "should be able to create a folder" do
    @folder = DomainFile.create_folder("My Folder")
    @folder.should be_valid
    @folder.parent_id.should == DomainFile.root_folder.id
  end
  
  it "should be able to extract a folder and recompress it to an archive" do
    File.open("#{RAILS_ROOT}/spec/fixtures/files/test_folder.zip") do |f| 
      @archive = DomainFile.create(:filename => f)
    end
    @files = @archive.extract(:single_folder => false)      
    @files.length.should == 1
    
    # Should have 1 folder in it with the rails.png file in it
    @folder = DomainFile.find(@files[0])
    @folder.file_type.should == 'fld'
    @folder.name.should == 'test_folder'
    @folder.children.length.should == 1
    
    @child = @folder.children[0]
    @child.file_type.should == 'img'
    @child.name.should == 'rails.png'
    
    # Make sure there's a file and a child file
    File.exists?(@child.filename).should be_true
    File.exists?(@child.filename(:icon)).should be_true
    
    
    @new_archive = @folder.download_directory
    @new_archive.extension.should == 'zip'
    @new_archive.file_type.should == 'doc'
    @new_archive.name.should == 'test_folder.zip'

    # Clean up the actual files
    @new_archive.destroy
    @archive.destroy
    @folder.destroy
    @child.destroy
  end
  
  it "should be able to make a public file private and vice versa" do
    @df.save
    
    public_filename =@df.filename
    @df.filename.should match /\/storage\//
    @df.update_private!(true)
    
    @df.filename.should match /\/private\//
    File.exists?(@df.filename).should be_true
    File.exists?(public_filename).should be_false
    
    @df.update_private!(false)
    
    @df.filename.should match /\/storage\//
    File.exists?(@df.filename).should be_true
  end
  
  it "should be able to return a editor url" do
    @df.save
    
    @df.editor_url.should == "/__fs__/#{@df.prefix}"
    @df.editor_url(:icon).should == "/__fs__/#{@df.prefix}:icon"
  end
  
  it "should be able to copy a file and create a new file" do
   @df.save
   
   @file = @df.copy_file
   
   @file.id.should_not be_blank
   @file.id.should_not == @df.id
   
   @file.filename.should_not == @df.id
   
   @file.destroy
   @df.destroy
  end
  
  it "should be able to replace a file" do
    @df.save

    fdata = fixture_file_upload("files/test.txt", 'text/plain')
    @textFile = DomainFile.create(:filename => fdata)

    assert_difference 'DomainFileVersion.count', 1 do
      @hash = @df.replace_file(:replace_id => @textFile.id)
    end

    @hash.should == {:domain_file_id => @df.id}

    @df.reload
    @df.name.should == 'test.txt'
    @df.document?.should be_true

    @version = DomainFileVersion.find :last
    @version.domain_file_id.should == @df.id

    @df.destroy
    @textFile.destroy
  end

  it "should not replace folders" do
    @df.save
    @folder = DomainFile.create_folder('Folder 1')
    assert_difference 'DomainFileVersion.count', 0 do
      @hash = @folder.replace_file(:replace_id => @df.id)
    end
    @hash.should be_nil

    assert_difference 'DomainFileVersion.count', 0 do
      @hash = @df.replace_file(:replace_id => @folder.id)
    end
    @hash.should be_nil

    @df.destroy
  end
  
end
