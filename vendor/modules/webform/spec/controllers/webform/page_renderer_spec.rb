require  File.expand_path(File.dirname(__FILE__)) + '/../../webform_spec_helper'

describe Webform::PageRenderer, :type => :controller do
  controller_name :page
  integrate_views

  reset_domain_tables :webform_forms, :webform_form_results, :end_users

  def generate_page_renderer(paragraph, options={}, inputs={})
    @rnd = build_renderer('/page', '/webform/page/' + paragraph, options, inputs)
  end

  it "should render form paragraph even when not setup" do
    @rnd = generate_page_renderer('form')
    @rnd.should_receive(:render_paragraph)
    renderer_get @rnd
  end

  describe "using a valid webform" do
    before(:each) do
      fields = [
        {:name => 'First Name', :field_type => 'string', :field_module => 'content/core_field'},
        {:name => 'Last Name', :field_type => 'string', :field_module => 'content/core_field'},
        {:name => 'Email', :field_type => 'email', :field_module => 'content/core_field'}
      ]

      features = [{:feature_handler => 'content/core_feature/email_target_connect', :feature_options => {:matched_fields => {:email => 'end_user.email', :first_name => 'end_user.first_name', :last_name => 'end_user.last_name'}}}]
      
      @model = WebformForm.new :name => 'Test'
      @model.content_model_fields = fields
      @model.content_model_features = features
      @model.save

      @destination_page = SiteVersion.default.root.add_subpage('success')

      @post_data = {:first_name => 'Tester', :last_name => 'Laster', :email => 'webform-tester@test.dev'}
    end

    it "should render the webform" do
      options = {:webform_form_id => @model.id, :destination_page_id => @destination_page.id, :email_to => nil, :captcha => nil}
      @rnd = generate_page_renderer('form', options)
      @result = WebformFormResult.new :webform_form_id => @model.id, :end_user_id => nil, :ip_address => '0.0.0.0'
      WebformFormResult.should_receive(:new).with(:webform_form_id => @model.id, :end_user_id => nil, :ip_address => '0.0.0.0').and_return(@result)
      renderer_get @rnd
    end

    it "should add a webform result and redirect" do
      options = {:webform_form_id => @model.id, :destination_page_id => @destination_page.id, :email_to => nil, :captcha => nil}
      @rnd = generate_page_renderer('form', options)

      assert_difference 'EndUser.count', 1 do
        assert_difference 'WebformFormResult.count', 1 do
          param_str = 'results_' + @rnd.paragraph.id.to_s
          renderer_post @rnd, param_str => @post_data
        end
      end

      @rnd.should redirect_paragraph(@destination_page.node_path)

      user = EndUser.find_by_email('webform-tester@test.dev')
      user.should_not be_nil
      user.first_name.should == 'Tester'
      user.last_name.should == 'Laster'

      webform_result = WebformFormResult.find(:last)
      webform_result.end_user_id.should == user.id
    end

    it "should add a webform result and display results" do
      options = {:webform_form_id => @model.id, :destination_page_id => nil, :email_to => nil, :captcha => nil}
      @rnd = generate_page_renderer('form', options)

      assert_difference 'EndUser.count', 1 do
        assert_difference 'WebformFormResult.count', 1 do
          param_str = 'results_' + @rnd.paragraph.id.to_s
          renderer_post @rnd, param_str => @post_data
        end
      end

      @rnd.should_not redirect_paragraph(@destination_page.node_path)

      user = EndUser.find_by_email('webform-tester@test.dev')
      user.should_not be_nil
      user.first_name.should == 'Tester'
      user.last_name.should == 'Laster'

      webform_result = WebformFormResult.find(:last)
      webform_result.end_user_id.should == user.id
    end

    it "should add a webform result with captcha" do
      options = {:webform_form_id => @model.id, :destination_page_id => @destination_page.id, :email_to => nil, :captcha => true}
      @rnd = generate_page_renderer('form', options)

      @captcha = WebivaCaptcha.new(@rnd)
      WebivaCaptcha.should_receive(:new).with(@rnd).and_return(@captcha)
      @captcha.should_receive(:validate).and_return(true)

      assert_difference 'EndUser.count', 1 do
        assert_difference 'WebformFormResult.count', 1 do
          param_str = 'results_' + @rnd.paragraph.id.to_s
          renderer_post @rnd, param_str => @post_data
        end
      end

      @rnd.should redirect_paragraph(@destination_page.node_path)

      user = EndUser.find_by_email('webform-tester@test.dev')
      user.should_not be_nil
      user.first_name.should == 'Tester'
      user.last_name.should == 'Laster'

      webform_result = WebformFormResult.find(:last)
      webform_result.end_user_id.should == user.id
    end

    it "should add a webform result and send webforms results as an email" do
      options = {:webform_form_id => @model.id, :destination_page_id => nil, :email_to => 'test-form@test.dev', :captcha => nil}
      @rnd = generate_page_renderer('form', options)

      assert_difference 'EndUser.count', 1 do
        assert_difference 'WebformFormResult.count', 1 do
          MailTemplateMailer.should_receive(:deliver_message_to_address).with('test-form@test.dev', anything(), anything())
          param_str = 'results_' + @rnd.paragraph.id.to_s
          renderer_post @rnd, param_str => @post_data
        end
      end

      @rnd.should_not redirect_paragraph(@destination_page.node_path)

      user = EndUser.find_by_email('webform-tester@test.dev')
      user.should_not be_nil
      user.first_name.should == 'Tester'
      user.last_name.should == 'Laster'

      webform_result = WebformFormResult.find(:last)
      webform_result.end_user_id.should == user.id
    end
  end
end
