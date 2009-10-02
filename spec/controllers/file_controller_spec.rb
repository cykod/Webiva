require File.dirname(__FILE__) + "/../spec_helper"

describe FileController do
  integrate_views
  
  reset_domain_tables :domain_files
  
  before(:each) do
    mock_editor
    
  end
   

  it "should be able to display the root folder with a couple of files and folders in it" do
    fdata = fixture_file_upload("files/rails.png",'image/jpeg')
    @image = DomainFile.create(:filename => fdata)    
    @folder = DomainFile.create_folder('Test Folder')
    
    get :index
    
    response.should render_template('file/index.rhtml')
    
    
    
    @image.destroy
    @folder.destroy
  end

end

