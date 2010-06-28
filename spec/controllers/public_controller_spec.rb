require File.dirname(__FILE__) + "/../spec_helper"

describe PublicController, "handling sending files" do
 
  reset_domain_tables :domain_file_sizes, :domain_files

  it "should return a valid file if the file exists" do
    fdata = fixture_file_upload("files/rails.png",'image/png')
    @df = DomainFile.create(:filename => fdata)    
    
     controller.should_receive(:myself).and_return(mock_model(EndUser, :editor? => true))
     
     if USE_X_SEND_FILE
       controller.should_receive(:x_send_file).with(@df.filename(:thumb),:type => @df.mime_type,:disposition => 'inline', :filename => @df.name)
     else
       controller.should_receive(:send_file).with(@df.filename(:thumb),:type => @df.mime_type,:disposition => 'inline', :filename => @df.name)
     end   
     
     url = @df.prefix.split("/")
     url[-1] += ":thumb"

     get :file_store, :prefix => url
     
     @df.destroy
  end
  
  it "should return a 404 if there's no file" do
     controller.should_receive(:myself).and_return(mock_model(EndUser, :editor? => true))
     
     get :file_store, :prefix => [ 'dfe','65','234' ]
     response.response_code.should == 404
  end

  it "should return a 404 if the user is not an editor" do
    fdata = fixture_file_upload("files/rails.png",'image/jpeg')
    @df = DomainFile.create(:filename => fdata)    

    controller.should_receive(:myself).and_return(mock_model(EndUser, :editor? => false))
    
    get :file_store, :prefix => @df.prefix.split("/") 
    response.response_code.should == 404
    
    @df.destroy
  end  
end

describe PublicController, "handle custom file sizes" do

  it "should return a new custom file size" do
    fdata = fixture_file_upload("files/oscar_bender.jpg",'image/jpeg')
    @df = DomainFile.create(:filename => fdata)    
    @test_dfs = DomainFileSize.create(:size_name => 'test-dfs', :name => 'Test Domain File Size',
                                          :operations => [ DomainFileSize::CroppedThumbnailOperation.new(:width => 64, :height => 64) ])
    
    @df.reload

     if USE_X_SEND_FILE
       controller.should_receive(:x_send_file).with(@df.filename('test-dfs'),:type => @df.mime_type,:disposition => 'inline', :filename => @df.name)
     else
       controller.should_receive(:send_file).with(@df.filename('test-dfs'),:type => @df.mime_type,:disposition => 'inline', :filename => @df.name)
     end      
    
    get :image,:domain_id => DomainModel.active_domain[:file_store].to_i,  :path =>  @df.prefix.split("/") + [ 'test-dfs', @df.name ]
    @df.destroy
  end

end
