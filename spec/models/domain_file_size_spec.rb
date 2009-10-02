require File.dirname(__FILE__) + "/../spec_helper"

# Test added version support by DomainFileVersion
# This tests a bunch of functionality on DomainFile as well

describe DomainFileSize do

  reset_domain_tables :domain_file_size, :domain_file
  
  def generate_file
    fdata = fixture_file_upload("files/oscar_bender.jpg",'image/jpeg')
    @df = DomainFile.create(:filename => fdata)
  end
  
  def generate_domain_file_size_operation(op)
    @test_dfs = DomainFileSize.create(:size_name => 'test-dfs', :name => 'Test Domain File Size',
                                            :operations => [ op ])
  
    @test_dfs.should be_valid
  end
  
  after(:each) do 
    @df.destroy if @df # Make sure we get rid of the files in the system
  end
  
  it "should be able to create a new thumbnail size and recrop the image to size" do
    generate_file
    generate_domain_file_size_operation(DomainFileSize::ThumbnailOperation.new(:width => 64, :height => 64))
                                            
    @test_dfs.should be_valid
    DomainFileSize.custom_sizes[:'test-dfs'].should be_true # Make sure the size exists
    
    fl = @test_dfs.execute(@df)
    @df.filename('test-dfs').should == fl # Make sure the filename is working
    File.exists?(@df.filename('test-dfs')).should be_true # Make sure the file exists
    @df.width('test-dfs').should == 64 # The width of the image should be 64 (we know this image is larger horizontally)
    @df.height('test-dfs').should <= 64 # The height of the image should be < 64
  end
  
  it "should be able to create a new cropped thumbnail that's exactly the correct size"  do
    generate_file
    generate_domain_file_size_operation(DomainFileSize::CroppedThumbnailOperation.new(:width => 64, :height => 64))


  
    fl = @test_dfs.execute(@df)
    @df.filename('test-dfs').should == fl # Make sure the filename is working
    File.exists?(@df.filename('test-dfs')).should be_true # Make sure the file exists
    @df.width('test-dfs').should == 64 # The width of the image should be 64 
    @df.height('test-dfs').should == 64 # The height of the image should be 64
  end
  
  it "should be able to create a new resized thumbnail that's exactly the correct size"  do
    generate_file
    generate_domain_file_size_operation(DomainFileSize::ResizeOperation.new(:width => 64, :height => 64))
  
    fl = @test_dfs.execute(@df)
    @df.filename('test-dfs').should == fl # Make sure the filename is working
    File.exists?(@df.filename('test-dfs')).should be_true # Make sure the file exists
    @df.width('test-dfs').should == 64 # The width of the image should be 64 
    @df.height('test-dfs').should == 64 # The height of the image should be 64
  end  
  
  
 it "should be able to create a new window size that will correctly size the image"  do
    generate_file
    generate_domain_file_size_operation(DomainFileSize::WindowOperation.new(:offset_x => 40, :offset_y => 40, :width => 64, :height => 64))
  
    fl = @test_dfs.execute(@df)
    @df.filename('test-dfs').should == fl # Make sure the filename is working
    File.exists?(@df.filename('test-dfs')).should be_true # Make sure the file exists
    @df.width('test-dfs').should == 64 # The width of the image should be 64 
    @df.height('test-dfs').should == 64 # The height of the image should be 64
  end    
  
end
