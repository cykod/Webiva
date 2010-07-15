require File.dirname(__FILE__) + "/../spec_helper"

describe FileController do
  integrate_views

  reset_domain_tables :domain_files, :end_users, :roles, :user_roles
  
  describe "editor tests" do
    before(:each) do
      mock_editor
      fdata = fixture_file_upload("files/rails.png",'image/png')
      @image = DomainFile.create(:filename => fdata)    
      @folder = DomainFile.create_folder('Test Folder')
      @subfolder = @folder.children.create(:name => 'Test Sub Folder', :file_type => 'fld', :special => '')
      fdata = fixture_file_upload('files/test.txt', 'text/plain')
      @testFile = DomainFile.create(:filename => fdata, :parent_id => @subfolder.id)
    end

    after(:each) do
      @testFile.destroy
      @subfolder.destroy
      @image.destroy
      @folder.destroy
    end

    it "should be able to display the root folder with a couple of files and folders in it" do
      get :index
      response.should render_template('file/index.rhtml')
      response.body.should include('Test Folder')
      response.body.should include('rails.png')
      response.body.should_not include('test.txt')
    end

    it "should be able to display a sub folder with a couple of files and folders in it" do
      get :index, :path => [@subfolder.id]
      response.should render_template('file/index.rhtml')
      response.body.should include('Test Folder')
      response.body.should include('Test Sub Folder')
      response.body.should include('test.txt')
      response.body.should_not include('rails.png')
    end

    it "should be able to display a the parent folder of a file" do
      get :index, :path => [@testFile.id]
      response.should render_template('file/index.rhtml')
      response.body.should include('Test Folder')
      response.body.should include('Test Sub Folder')
      response.body.should include('test.txt')
      response.body.should_not include('rails.png')
    end

    it "should load a folder" do
      get :load_folder, :path => [@subfolder.id]
      response.should render_template('file/load_folder.rjs')
    end

    it "should load a folder and specify a file" do
      get :load_folder, :path => [@subfolder.id], :file_id => @image.id
      response.should render_template('file/load_folder.rjs')
    end

    it "should update icon sizes" do
      get :update_icon_sizes, :folder_id => @subfolder.id, :file_ids => [@testFile.id], :load_request => 1, :icon_size => 140, :thumb_size => 'icon'
      response.should render_template('file/update_icon_sizes.rjs')
    end

    describe "popup tests" do
      it "should display popup window" do
	get :popup
	response.should render_template('file/index.rhtml')
      end

      it "should display popup window of a folder" do
	DomainFile.should_receive(:find_by_id).once.with(@subfolder.id).and_return(@subfolder)
	get :popup, :path => [@subfolder.id]
	response.should render_template('file/index.rhtml')
      end

      it "should display popup window of a folder using file_id" do
	get :popup, :file_id => @subfolder.id
	response.should render_template('file/index.rhtml')
      end

      it "should display popup window even if folder of file is missing" do
	get :popup, :path => [9999]
	response.should render_template('file/index.rhtml')
      end

      it "should display popup window of a parent folder of a file" do
	DomainFile.should_receive(:find_by_id).once.with(@testFile.id).and_return(@testFile)
	@testFile.should_receive(:parent).once.and_return(@subfolder)
	get :popup, :path => [@testFile.id]
	response.should render_template('file/index.rhtml')
      end

      it "should display popup window of a parent folder of a file using file_id" do
	get :popup, :file_id => @testFile.id
	response.should render_template('file/index.rhtml')
      end

      it "should display popup window of the last folder seen" do
	controller.session[:cms_last_folder_id] = @subfolder.id
	DomainFile.should_receive(:find_by_id_and_file_type).once.with(@subfolder.id, 'fld').and_return(@subfolder)
	get :popup
	response.should render_template('file/index.rhtml')
      end
    end

    it "should load file details" do
      get :load_details, :file_id => @testFile.id
      response.should render_template('file/load_details.rjs')
    end

    describe "file manager update tests" do
      def generate_workling(upload_key, file_processor)
	@workling = mock
	Workling.should_receive(:return).and_return(@workling)
	@workling.should_receive(:get).and_return(file_processor)
      end

      it "should render nothing if upload_key is not specified" do
	get :file_manager_update
	response.body.strip.empty?.should be_true
      end

      it "should render processing if upload_key is specified and file progress is not found" do
	generate_workling 'my_uploaded_file_key', nil
	get :file_manager_update, :upload_key => 'my_uploaded_file_key'
	response.should render_template('file/_file_manager_processing.rjs')
      end

      it "should render processing if upload_key is specified and file progress has not finished" do
	generate_workling 'my_uploaded_file_key', {:processed => false, :uploaded_ids => [@testFile.id]}
	get :file_manager_update, :upload_key => 'my_uploaded_file_key'
	response.should render_template('file/_file_manager_processing.rjs')
      end

      it "should render processed if upload_key is specified and file progress has finished" do
	generate_workling 'my_uploaded_file_key', {:processed => true, :uploaded_ids => [@testFile.id]}
	get :file_manager_update, :upload_key => 'my_uploaded_file_key'
	response.should render_template('file/_file_manager_update.rjs')
      end
    end

    it "should be able to upload a file" do
      fdata = fixture_file_upload("files/system_domains.gif",'image/gif')
      FileWorker.should_receive(:async_do_work).once.and_return('my_upload_key')

      assert_difference 'DomainFile.count', 1 do
        post 'upload', :upload_file => {:filename => fdata, :parent_id => @subfolder.id}, :extract_archive => false, :replace_same => false
      end

      @df = DomainFile.find :last
      File.exists?(@df.filename).should be_true
      (@df.filename =~ /system_domains.gif$/).should be_true
    end

    it "should responded to progress" do
      get :progress
      response.status.should == '200 OK'
    end

    it "should be able to rename a file or folder" do
      post :rename_file, :file_id => @testFile.id, :file => {:name => 'my_new_test_file.txt'}
      response.should render_template('file/rename_file.rjs')
      @testFile.reload
      @testFile.name.should == 'my_new_test_file.txt'
    end

    describe "move files tests" do
      it "should be able to move files to a parent folder" do
	post :move_files, :file_id => [@testFile.id], :folder_id => @folder.id
	@testFile.reload
	@testFile.parent_id.should == @folder.id
      end

      it "should be able to move files to a new folder" do
	post :move_files, :file_id => [@image.id], :folder_id => @subfolder.id
	@image.reload
	@image.parent_id.should == @subfolder.id
      end
    end

    describe "replace file tests" do
      it "should be able replace a file with a different file" do
        DomainFile.should_receive(:find_by_id).once.with(@testFile.id).and_return(@testFile)
        DomainFile.should_receive(:find_by_id).once.with(@image.id).and_return(@image)
        @testFile.should_receive(:run_worker).once.with(:replace_file, :replace_id => @image.id)
	post :replace_file, :file_id => @testFile.id, :replace_id => @image.id
	response.should render_template('file/replace_file.rjs')
      end

      it "should not be able replace a file with a folder" do
        DomainFile.should_receive(:find_by_id).once.with(@testFile.id).and_return(@testFile)
        DomainFile.should_receive(:find_by_id).once.with(@subfolder.id).and_return(@subfolder)
        @testFile.should_receive(:run_worker).exactly(0)
	post :replace_file, :file_id => @testFile.id, :replace_id => @subfolder.id
      end

      it "should not be able replace a folder with a file" do
        DomainFile.should_receive(:find_by_id).once.with(@subfolder.id).and_return(@subfolder)
        DomainFile.should_receive(:find_by_id).once.with(@testFile.id).and_return(@testFile)
        @subfolder.should_receive(:run_worker).exactly(0)
	post :replace_file, :file_id => @subfolder.id, :replace_id => @testFile.id
      end

      it "should not replace the same file" do
	DomainFile.should_receive(:find_by_id).twice.with(@image.id).and_return(@image)
        @image.should_receive(:run_worker).exactly(0)
	post :replace_file, :file_id => @image.id, :replace_id => @image.id
      end

      it "should be able to delete a file version" do
	@version = DomainFileVersion.archive( @image )
	@version.id.should_not be_nil

	post :delete_revision, :revision_id => @version.id
	response.should render_template('file/delete_revision.rjs')

	@deletedVersion = DomainFileVersion.find_by_id(@version.id)
	@deletedVersion.should be_nil
      end

      it "should be able to extract a file version" do
	@version = DomainFileVersion.archive( @image )
	@version.id.should_not be_nil

        DomainFileVersion.should_receive(:find_by_id).once.with(@version.id).and_return(@version)
        @version.should_receive(:run_worker).with(:extract_file)

        post :extract_revision, :revision_id => @version.id
        response.should render_template('file/extract_revision.rjs')
      end

      it "should be able to copy a file" do
	assert_difference 'DomainFile.count', 1 do
	  post :copy_file, :file_id => @image.id
	  response.should render_template('file/copy_file.rjs')
	end

	@file = DomainFile.find(:last)
	@file.id.should_not == @image.id
	@file.name.should == @image.name
	@file.parent_id.should == @image.parent_id
	@file.destroy
      end

      describe "create folder tests" do
	it "should be able to create a new folder" do
	  assert_difference 'DomainFile.count', 1 do
	    post :create_folder, :folder_id => @folder.id
	    response.should render_template('file/_create_folder.rjs')
	  end

	  @newFolder = DomainFile.find(:last)
	  @newFolder.folder?.should be_true
	  @newFolder.id.should_not == @folder.id
	  @newFolder.name.should == 'New Folder'
	  @newFolder.parent_id.should == @folder.id
	end

	it "should not be able to create a new folder if folder id is a file" do
	  assert_difference 'DomainFile.count', 0 do
	    post :create_folder, :folder_id => @image.id
	    response.body.strip.empty?.should be_true
	  end
	end
      end
    end

    it "should be able to delete a file" do
      assert_difference 'DomainFile.count', -1 do
	post :delete_file, :file_id => @image.id
	response.body.strip.empty?.should be_true
      end

      @missingImage = DomainFile.find_by_id(@image.id)
      @missingImage.should be_nil
    end

    it "should be able to delete files" do
      assert_difference 'DomainFile.count', -2 do
	post :delete_files, :file_id => [@image.id, @testFile.id]
	response.body.strip.empty?.should be_true
      end

      @missingImage = DomainFile.find_by_id(@image.id)
      @missingImage.should be_nil

      @missingImage = DomainFile.find_by_id(@testFile.id)
      @missingImage.should be_nil
    end

    it "should be able to delete a folder and all of its contents" do
      assert_difference 'DomainFile.count', -3 do
	post :delete_file, :file_id => @folder.id
	response.body.strip.empty?.should be_true
      end

      @missing = DomainFile.find_by_id(@testFile.id)
      @missing.should be_nil
      @missing = DomainFile.find_by_id(@subfolder.id)
      @missing.should be_nil
      @missing = DomainFile.find_by_id(@folder.id)
      @missing.should be_nil
    end

    it "should be able to make a file private" do
      post :make_private, :file_id => @image.id
      response.should render_template('file/_update_file.rjs')
      @image.reload
      @image.private?.should be_true
    end

    it "should be able to make a file public" do
      @image.update_private!(true)
      @image.reload
      @image.private?.should be_true

      post :make_public, :file_id => @image.id
      response.should render_template('file/_update_file.rjs')

      @image.reload
      @image.private?.should be_false
    end

    it "should be able to archive a folder" do
      DomainModel.should_receive(:run_worker).once.with('DomainFile',@folder.id,:download_directory)
      get :folder_archive, :folder_id => @folder.id
    end

    it "should be able to switch processor on a file" do
      DomainModel.should_receive(:run_worker).once.with('DomainFile',@image.id,:update_processor, {:processor => 'processing'})
      get :switch_processor, :file_id => @image.id, :file_processor => 'processing'
      response.should render_template('file/_update_file.rjs')
    end

    it "should be able to fetch a file" do
      get :priv, :path => [@image.id]
      response.status.should == '200 OK'
    end

    it "should be able to fetch a file with size" do
      get :priv, :path => [@image.id, 'thumb']
      response.status.should == '200 OK'
    end

    it "should be able to search for files" do
      post :search, :search => {:search => 'rails', :order => 'name'}
      response.should render_template('file/_search_results.rhtml')
      response.body.should include('rails.png')
    end

    describe "edit file tests" do
      it "should be able to edit the contents of a text file" do
	post :edit_file, :file_id => @testFile.id, :contents => 'new file contents'
	response.should render_template('file/_edited_file.rjs')
	@testFile.reload
	@testFile.contents.should == 'new file contents'
      end

      it "should not be able to edit an image" do
	post :edit_file, :file_id => @image.id, :contents => 'new file contents'
	response.should render_template('file/_edit_file.rhtml')
	@image.reload
	@testFile.contents.should_not == 'new file contents'
      end
    end
  end

  describe "user tests" do
    it "should not be able to access a private file even if a member" do
      mock_user
      fdata = fixture_file_upload("files/rails.png",'image/png')
      @image = DomainFile.create(:filename => fdata)
      @image.update_private!(true)

      controller.should_receive(:send_file).exactly(0)
      get :priv, :path => [@image.id]

      @image.destroy
    end

    it "should not be able to access a private file if not logged in" do
      fdata = fixture_file_upload("files/rails.png",'image/png')
      @image = DomainFile.create(:filename => fdata)
      @image.update_private!(true)

      controller.should_receive(:send_file).exactly(0)
      get :priv, :path => [@image.id]

      @image.destroy
    end
  end
end

