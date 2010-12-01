require File.dirname(__FILE__) + "/../spec_helper"

describe MembersController do
  integrate_views

  reset_domain_tables :end_users, :user_subscriptions, :user_subscription_entries, :tags, :mail_templates, :end_user_addresses, :tag_notes, :end_user_tags, :market_segments, :user_segments, :user_segment_caches, :end_user_note

  describe "editor tests" do
    before(:each) do
      mock_editor
      @user1 = EndUser.push_target('user1@test.dev', :first_name => 'User1', :last_name => 'Last1')
      @user2 = EndUser.push_target('user2@test.dev', :first_name => 'User2', :last_name => 'Last2')
      @user3 = EndUser.push_target('user3@test.dev', :first_name => 'User3', :last_name => 'Last3')
      @user4 = EndUser.push_target('user4@test.dev', :first_name => 'User4', :last_name => 'Last4')
      @user5 = EndUser.push_target('user5@test.dev', :first_name => 'User5', :last_name => 'Last5', :membership_id => 'number5')
      @subscription = UserSubscription.create :name => 'test'

      @user1.action('/editor/auth/user_registration', :identifier => @user1.email)
      @user2.action('/editor/auth/user_registration', :identifier => @user2.email)
      @user3.action('/editor/auth/user_registration', :identifier => @user3.email)

      @user1.tag(['yourit'])
    end

    it "should handle user list" do
      # Test all the permutations of an active table
      controller.should handle_active_table(:email_targets_table) do |args|
	post 'display_targets_table', args
      end
    end

    it "should render index page" do
      @output = get 'index'
      @output.status.should == '200 OK'
    end

    describe "lookup_autocomplete tests:" do
      it "should render nothing" do
	controller.should_receive(:render).with(:nothing => true)
	@output = get 'lookup_autocomplete'
      end

      it "should render nothing with empty string" do
	controller.should_receive(:render).with(:nothing => true)
	@output = get 'lookup_autocomplete', :member => ''
      end

      it "should lookup by first_name" do
	@output = get 'lookup_autocomplete', :member => 'user'
	@output.status.should == '200 OK'
	@output.body.should include('User1')
      end

      it "should lookup by last_name" do
	@output = get 'lookup_autocomplete', :member => 'last2, user'
	@output.status.should == '200 OK'
	@output.body.should include('User2')
      end

      it "should lookup by membership_id" do
	@output = get 'lookup_autocomplete', :member => 'number5'
	@output.status.should == '200 OK'
	@output.body.should include('User5')
      end
    end

    describe "create end_user tests:" do
      it "should render create page" do
	assert_difference 'EndUser.count', 0 do
	  @output = get 'create'
	  @output.status.should == '200 OK'
	end
      end

      it "should create a new user" do
	assert_difference 'EndUser.count', 1 do
	  @output = post 'create', :commit => true, :user_options => {:email => 'test@test.dev', :user_class_id => UserClass.domain_user_class_id, :tag_names => 'create'}
	end

	@user = EndUser.find_by_email('test@test.dev')
	@user.should_not be_nil
	@user.user_class_id.should == UserClass.domain_user_class_id
      end

      it "should not create a new user if not committing" do
	assert_difference 'EndUser.count', 0 do
	  @output = post 'create', :commit => false, :user_options => {:email => 'test@test.dev', :user_class_id => UserClass.domain_user_class_id}
	end

	@user = EndUser.find_by_email('test@test.dev')
	@user.should be_nil
      end

      it "should create a new user and subscribe" do
	assert_difference 'EndUser.count', 1 do
	  @output = post 'create', :commit => true, :user_options => {:email => 'test@test.dev'}, :subscription => {'0' => 1, @subscription.id.to_s => 'on'}
	end

	@user = EndUser.find_by_email('test@test.dev')
	@user.should_not be_nil
	@user.user_class_id.should == UserClass.default_user_class_id

	@entry = UserSubscriptionEntry.find_by_end_user_id_and_user_subscription_id(@user.id, @subscription.id)
	@entry.should_not be_nil
      end
    end

    describe "edit end_user tests:" do
      it "should render edit page" do
	assert_difference 'EndUser.count', 0 do
	  @output = get 'edit', :path => [@user1.id]
	  @output.status.should == '200 OK'
	end
      end

      it "should edit a user data" do
	assert_difference 'EndUser.count', 0 do
	  @output = post 'edit', :path => [@user1.id], :commit => true, :user_options => {:first_name => 'EditedFirstName'}, :address => {}, :work_address => {}, :billing_address => {}, :shipping_address => {}
	end
	@user1.reload
	@user1.first_name.should == 'EditedFirstName'
      end

      it "should not edit a user if not committing" do
	assert_difference 'EndUser.count', 0 do
	  @output = post 'edit', :path => [@user1.id], :commit => false, :user_options => {:first_name => 'EditedFirstName'}, :address => {}, :work_address => {}, :billing_address => {}, :shipping_address => {}
	end
	@user1.reload
	@user1.first_name.should == 'User1'
      end

      it "should edit a user data and address" do
	assert_difference 'EndUserAddress.count', 1 do
	  @output = post 'edit', :path => [@user1.id], :commit => true, :user_options => {:first_name => 'EditedFirstName'}, :address => {:zip => '55555'}, :work_address => {}, :billing_address => {}, :shipping_address => {}
	end
	@user1.reload
	@user1.first_name.should == 'EditedFirstName'
	@user1.address.zip.should == '55555'
      end

      it "should edit a user and subscribe" do
	assert_difference 'UserSubscriptionEntry.count', 1 do
	  @output = post 'edit', :path => [@user1.id], :commit => true, :user_options => {:first_name => 'EditedFirstName'}, :address => {}, :work_address => {}, :billing_address => {}, :shipping_address => {}, :subscription => {'0' => 1, @subscription.id.to_s => 'on'}
	end
	@user1.reload
	@user1.first_name.should == 'EditedFirstName'

	@entry = UserSubscriptionEntry.find_by_end_user_id_and_user_subscription_id(@user1.id, @subscription.id)
	@entry.should_not be_nil
      end

      it "should edit a user and unsubscribe" do
	@subscription.subscribe_user @user1

	@entry = UserSubscriptionEntry.find_by_end_user_id_and_user_subscription_id(@user1.id, @subscription.id)
	@entry.should_not be_nil

	assert_difference 'UserSubscriptionEntry.count', -1 do
	  @output = post 'edit', :path => [@user1.id], :commit => true, :user_options => {:first_name => 'EditedFirstName'}, :address => {}, :work_address => {}, :billing_address => {}, :shipping_address => {}, :subscription => {'0' => 1}
	end
	@user1.reload
	@user1.first_name.should == 'EditedFirstName'

	@entry = UserSubscriptionEntry.find_by_end_user_id_and_user_subscription_id(@user1.id, @subscription.id)
	@entry.should be_nil
      end
    end

    it "should handle user actions list" do
      # Test all the permutations of an active table
      controller.should handle_active_table(:user_actions_table) do |args|
	args[:path] = [@user1.id]
	post 'display_user_actions_table', args
      end
    end

    it "should render view page" do
      @output = get 'view', :path => [@user1.id]
      @output.status.should == '200 OK'
    end

    it "should be able to login as different user" do
      controller.should_receive(:process_login).with(@user1)
      @output = get 'login', :path => [@user1.id]
    end

    it "should render member_visits partial" do
      @output = get 'member_visits', :path => [@user1.id]
      @output.status.should == '200 OK'
    end

    it "should render add_tags_form partial" do
      @output = get 'add_tags_form'
      @output.status.should == '200 OK'
    end

    it "should render remove_tags_form partial" do
      @output = get 'remove_tags_form', :user_ids => @user1.id.to_s
      @output.status.should == '200 OK'
    end

    it "should handle display tags list" do
      # Test all the permutations of an active table
      controller.should handle_active_table(:tags_table) do |args|
	post 'display_tags_table'
      end
    end

    it "should render tags page and create tag notes" do
      TagNote.delete_all
      assert_difference 'TagNote.count', Tag.count do
	@output = get 'tags'
	@output.status.should == '200 OK'
      end
    end

    it "should render tag_details page" do
      @output = get 'tag_details', :path => [1]
      @output.status.should == '200 OK'
    end

    it "should be able to update tag_details" do
      @note = TagNote.find(:first)
      @note.should_not be_nil
      @output = post 'tag_details', :path => [@note.id], :tag_note => {:description => 'test note'}
      @output.status.should == '200 OK'
      @note.reload
      @note.description.should == 'test note'
    end

    describe "handle end_user table actions" do
      it "should be able to delete a user" do
	@output = post 'display_targets_table', :table_action => 'delete', :user => {@user1.id => @user1.id}
	@deleted_user = EndUser.find_by_id @user1.id
	@deleted_user.should be_nil
      end

      it "should be able to add tags to users" do
	@output = post 'display_targets_table', :table_action => 'add_tags', :user => {@user1.id => @user1.id}, :added_tags => 'new_tag'
	@user1.reload
	@user1.tag_names.include?('New_tag').should be_true
      end

      it "should be able to remove tags to users" do
	@user1.tag(['new_tag'])
	@user1.reload
	@user1.tag_names.include?('New_tag').should be_true
	@output = post 'display_targets_table', :table_action => 'remove_tags', :user => {@user1.id => @user1.id}, :removed_tags => 'new_tag'
	@user1.reload
	@user1.tag_names.include?('New_tag').should_not be_true
      end

      it "should be able to clear tags to users" do
	@user1.tag(['new_tag'])
	@user1.reload
	@user1.tag_names.include?('New_tag').should be_true
	@output = post 'display_targets_table', :table_action => 'clear_tags', :user => {@user1.id => @user1.id}
	@user1.reload
	@user1.tag_names.blank?.should be_true
      end
    end

    it "should render generate_vip page" do
      @output = get 'generate_vip'
      @output.status.should == '200 OK'
    end
  end

  describe "user tests" do
    before(:each) do
      mock_user
      @user1 = EndUser.push_target('user1@test.dev', :first_name => 'User1', :last_name => 'Last1')
      @user2 = EndUser.push_target('user2@test.dev', :first_name => 'User2', :last_name => 'Last2')
      @user3 = EndUser.push_target('user3@test.dev', :first_name => 'User3', :last_name => 'Last3')
      @user4 = EndUser.push_target('user4@test.dev', :first_name => 'User4', :last_name => 'Last4')
      @user5 = EndUser.push_target('user5@test.dev', :first_name => 'User5', :last_name => 'Last5', :membership_id => 'number5')
      @subscription = UserSubscription.create :name => 'test'

      @user1.action('/editor/auth/user_registration', :identifier => @user1.email)
      @user2.action('/editor/auth/user_registration', :identifier => @user2.email)
      @user3.action('/editor/auth/user_registration', :identifier => @user3.email)
    end

    it "none editors should not be able to login as different user" do
      controller.should_receive(:process_login).exactly(0)
      @output = get 'login', :path => [@user1.id]
    end
  end

  describe "user lists" do
    before(:each) do
      mock_editor
      @user1 = EndUser.push_target('user1@test.dev', :first_name => 'User1', :last_name => 'Last1')
      @user2 = EndUser.push_target('user2@test.dev', :first_name => 'User2', :last_name => 'Last2')
      @user3 = EndUser.push_target('user3@test.dev', :first_name => 'User3', :last_name => 'Last3')
      @user4 = EndUser.push_target('user4@test.dev', :first_name => 'User4', :last_name => 'Last4')
      @user5 = EndUser.push_target('user5@test.dev', :first_name => 'User5', :last_name => 'Last5', :membership_id => 'number5')
      @subscription = UserSubscription.create :name => 'test'

      @user1.action('/editor/auth/user_registration', :identifier => @user1.email)
      @user2.action('/editor/auth/user_registration', :identifier => @user2.email)
      @user3.action('/editor/auth/user_registration', :identifier => @user3.email)

      @segment1 = UserSegment.create :name => 'Segment 1', :segment_type => 'filtered', :segment_options_text => 'created.since(1, "days")', :main_page => false
      @segment1.refresh

      @segment2 = UserSegment.create :name => 'Segment 2', :segment_type => 'filtered', :segment_options_text => 'created.before(1, "days")', :main_page => true
      @segment2.refresh

      @segment3 = UserSegment.create :name => 'Custom Segment', :segment_type => 'custom', :main_page => true
      @segment3.add_ids [@user4.id, @user3.id]
    end

    it "should handle user list" do
      # Test all the permutations of an active table
      controller.should handle_active_table(:user_segments_table) do |args|
	post 'user_segments_table', args
      end
    end

    it "should be able to delete a user list" do
      @output = post 'user_segments_table', :table_action => 'delete', :user_segments => {@segment1.id => @segment1.id}
      @deleted_segment = UserSegment.find_by_id @segment1.id
      @deleted_segment.should be_nil
    end

    it "should be able to add segments to main_page" do
      @segment1.main_page.should be_false
      @output = post 'user_segments_table', :table_action => 'add', :user_segments => {@segment1.id => @segment1.id}
      @segment1.reload
      @segment1.main_page.should be_true
    end

    it "should be able to remove segments from the main_page" do
      @segment2.main_page.should be_true
      @output = post 'user_segments_table', :table_action => 'remove', :user_segments => {@segment2.id => @segment2.id}
      @segment2.reload
      @segment2.main_page.should be_false
    end

    it "should be able to create a user list" do
      assert_difference 'UserSegment.count', 1 do
        post 'create_segment', :commit => 1, :segment => {:name => 'Segment 3', :segment_options_text => 'email.like("%test.dev")'}
      end
      @segment = UserSegment.find(:last)
      @segment.end_user_ids.length.should == 5
    end

    it "should be able to edit a user list" do
      assert_difference 'UserSegment.count', 0 do
        post 'edit_segment', :path => [@segment1.id], :commit => 1, :segment => {:name => 'New Segment Name', :segment_options_text => 'email.like("%test.dev")'}
      end
      @segment1.reload
      @segment1.name.should == 'New Segment Name'
      @segment1.end_user_ids.length.should == 5
    end

    it "should be able to copy a user list" do
      assert_difference 'UserSegment.count', 1 do
        post 'copy_segment', :path => [@segment1.id], :commit => 1, :segment => {}
      end
      @segment = UserSegment.find(:last)
      @segment.segment_options_text.should == @segment1.segment_options_text
    end

    it "should be able to refresh a user list" do
      @segment1.last_count.should == 5

      EndUser.push_target('user6@test.dev')

      get 'refresh_segment', :path => [@segment1.id]

      @segment1.reload
      @segment1.last_count.should == 6
    end

    it "should be able to render add_users_form" do
      get 'add_users_form'
    end

    it "should be able to select and existing custom user segment" do
      post 'add_users_form', :choice => 'existing', :segment => {:id => @segment3.id}
    end

    it "should be able to create a custom user segment" do
      assert_difference 'UserSegment.count', 1 do
        post 'add_users_form', :choice => 'new', :segment => {:name => 'new segment'}
      end
      @segment = UserSegment.find(:last)
      @segment.name.should == 'new segment'
    end

    it "should be able to add users to a custom segment" do
      @segment3.last_count.should == 2
      post 'display_targets_table', :table_action => 'add_users', :user_segment_id => @segment3.id, :user => {@user5.id => @user5.id}
      @segment3.reload
      @segment3.last_count.should == 3
    end

    it "should be able to remove users from a custom segment" do
      @segment3.last_count.should == 2
      post 'display_targets_table', :table_action => 'remove_users', :path => [@segment3.id], :user => {@user4.id => @user4.id}
      @segment3.reload
      @segment3.last_count.should == 1
    end

    it "should be able to render the builder" do
      get 'builder'
    end

    it "should be able to render the custom builder" do
      post 'builder', :filter => 'custom'
    end

    it "should be able to render the builder for a segment" do
      post 'builder', :path => [@segment1.id]
    end

    it "should render operation partial" do
      post 'update_builder', :operation => 1, :builder => @segment1.to_builder
    end

    it "should render expression partial" do
      post 'update_builder', :expression => 1, :builder => @segment1.to_builder
    end
  end

  it "should be able to update options" do
    mock_editor
    post 'options', :commit => 1, :options => {:order_by => 'created', :order_direction => 'DESC', :fields => ['gender']}
    controller.class.module_options.fields.should == ['gender']
  end

  it "should be able to leave notes about users" do
    mock_editor
    user = EndUser.push_target 'user1@test.dev'

    assert_difference 'EndUserNote.count', 1 do
      post 'note', :path => [user.id], :note => {:note => 'New note message'}
    end

    note = EndUserNote.find :last
    note.end_user_id.should == user.id
    note.note.should == 'New note message'
  end
end
