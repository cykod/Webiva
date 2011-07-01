require File.dirname(__FILE__) + "/../spec_helper"

describe ParagraphFeature, :type => :view do

  reset_domain_tables :end_users, :end_user_addresses, :domain_files, :site_modules

  before(:each) do
    @feature = ParagraphFeature.standalone_feature
  end

  it "should render a simple tag" do
    data = { :url => 'http://www.google.com' }
    @output = @feature.parse_inline("Link:<cms:go_link>Google</cms:go_link>") do |c|
      c.link_tag('go') { |t| data[:url] }
    end

    @output.should have_tag('a', :href => 'http//www.google.com', :text => 'Google')
  end

  it "should render a simple tag using href" do
    data = { :url => 'http://www.google.com' }
    @output = @feature.parse_inline("Link:<a <cms:go_href/>>Google</a>") do |c|
      c.link_tag('go') { |t| data[:url] }
    end
    @output.should have_tag('a', :href => 'http//www.google.com', :text => 'Google')
  end

  it "should render a simple tag using url" do
    data = { :url => 'http://www.google.com' }
    @output = @feature.parse_inline("Link:<a href='<cms:go_url/>'>Google</a>") do |c|
      c.link_tag('go') { |t| data[:url] }
    end
    @output.should have_tag('a', :href => 'http//www.google.com', :text => 'Google')
  end

  it "should render a simple attribute tag" do
    person = mock :first_name => 'First', :last_name => 'Last', :email => 'test@test.dev'
    data = { :person => person }
    @output = @feature.parse_inline("<cms:person:first_name/>, <cms:person:last_name/>, <cms:person:email/>") do |c|
      c.expansion_tag('person') { |t| t.locals.person = data[:person] }
      c.attribute_tags('person', %w(first_name last_name email)) { |t| t.locals.person }
    end
    @output.should == "First, Last, test@test.dev"
  end

  it "should render escape tag data" do
    data = "</div>try to break the layers\n"
    @output = @feature.parse_inline("<cms:data/>") do |c|
      c.h_tag('data') { |t| data }
    end
    @output.should == "&lt;/div&gt;try to break the layers\n"
  end

  it "should render escape tag data and use simple format" do
    data = "</div>try to break the layers\n"
    @output = @feature.parse_inline("<cms:data><cms:value/></cms:data>") do |c|
      c.h_tag('data', 'value', :format => :simple) { |t| data }
    end
    @output.should have_tag('p', :text => "&lt;/div&gt;try to break the layers")
  end

  it "should render missing data if data is nil" do
    data = nil
    @output = @feature.parse_inline("<cms:data><cms:value/></cms:data><cms:no_data>missing data</cms:no_data>") do |c|
      c.h_tag('data') { |t| data }
    end
    @output.should == "missing data"
  end

  it "should render value tag" do
    data = 'my data'
    @output = @feature.parse_inline("<cms:data><cms:value/></cms:data><cms:no_data>missing data</cms:no_data>") do |c|
      c.value_tag('data') { |t| data }
    end
    @output.should == "my data"
  end

  it "should not render value tag" do
    data = nil
    @output = @feature.parse_inline("<cms:data><cms:value/></cms:data><cms:no_data>missing data</cms:no_data>") do |c|
      c.value_tag('data') { |t| data }
    end
    @output.should == "missing data"
  end

  it "should render a loop tag" do
    data = [mock(:first_name => 'First1', :last_name => 'Last1', :email => 'test1@test.dev'),
            mock(:first_name => 'First2', :last_name => 'Last2', :email => 'test2@test.dev')]

    @output = @feature.parse_inline("<cms:contacts><cms:contact><cms:first_name/> <cms:last_name/>: <cms:email/><br/></cms:contact></cms:contacts><cms:no_contacts>missing data</cms:no_contacts>") do |c|
      c.loop_tag('contact') { |t| data }
      c.attribute_tags('contact', %w(first_name last_name email)) { |t| t.locals.contact }
    end
    @output.should == "First1 Last1: test1@test.dev<br/>First2 Last2: test2@test.dev<br/>"
  end

  it "should not render a loop tag" do
    data = nil

    @output = @feature.parse_inline("<cms:contacts><cms:contact><cms:first_name/> <cms:last_name/>: <cms:email/><br/></cms:contact></cms:contacts><cms:no_contacts>missing data</cms:no_contacts>") do |c|
      c.loop_tag('contact') { |t| data }
      c.attribute_tags('contact', %w(first_name last_name email)) { |t| t.locals.contact }
    end
    @output.should == "missing data"
  end

  it "should expand tag" do
    data = true
    @output = @feature.parse_inline("<cms:data>have data</cms:data><cms:no_data>missing data</cms:no_data>") do |c|
      c.expansion_tag('data') { |t| data }
    end
    @output.should == "have data"
  end

  it "should not expand tag" do
    data = nil
    @output = @feature.parse_inline("<cms:data>have data</cms:data><cms:no_data>missing data</cms:no_data>") do |c|
      c.expansion_tag('data') { |t| data }
    end
    @output.should == "missing data"
  end

  it "should not expand tag using not_data" do
    data = nil
    @output = @feature.parse_inline("<cms:data>have data</cms:data><cms:not_data>missing data using not</cms:not_data>") do |c|
      c.expansion_tag('data') { |t| data }
    end
    @output.should == "missing data using not"
  end

  it "should render date tag" do
    data = Time.now
    format = '%m/%d/%Y'
    @output = @feature.parse_inline("<cms:date/>") do |c|
      c.date_tag('date') { |t| data }
    end
    @output.should == data.localize(format)
  end

  it "should render end user table" do
    EndUser.push_target 'test1@test.dev', :first_name => 'First1', :last_name => 'Last1'
    EndUser.push_target 'test2@test.dev', :first_name => 'First2', :last_name => 'Last2'

    @feature.renderer.should_receive(:params).any_number_of_times.and_return({})
    @feature.renderer.should_receive(:session).any_number_of_times.and_return({})

    tbl = @feature.renderer.end_user_table(:list,
					   EndUser, 
					   [ EndUserTable.column(:string,'first_name'),
					     EndUserTable.column(:string,'last_name')
					   ])

    @feature.renderer.end_user_table_generate tbl

    @output = @feature.parse_inline("<cms:list columns='First Name,Last Name'><tr><td><cms:first_name/></td><td><cms:last_name/></td></tr></cms:list>") do |c|
      c.end_user_table_tag('list', 'end_user', :refresh_url => '/test.js') { |t| tbl }
      c.h_tag('list:first_name') { |t| t.locals.end_user.first_name }
      c.h_tag('list:last_name') { |t| t.locals.end_user.last_name }
    end

    @output.should have_tag('td', :text => 'First1')
    @output.should have_tag('td', :text => 'First2')
    @output.should have_tag('td', :text => 'Last1')
    @output.should have_tag('td', :text => 'Last2')
  end

  it "should render end user tags" do
    data = EndUser.push_target 'test1@test.dev', :first_name => 'First1', :last_name => 'Last1'

    @output = @feature.parse_inline("<cms:user><cms:name/> <cms:profile/> <cms:profile_name/> <cms:first_name/> <cms:last_name/> <cms:logged_in>logged in</cms:logged_in><cms:not_logged_in>logged out</cms:not_logged_in> <cms:myself>it is me</cms:myself><cms:not_myself>not me</cms:not_myself></cms:user>") do |c|
      c.user_tags('user') { |t| data }
    end
    @output.should == "First1 Last1 #{UserClass.default_user_class_id} #{UserClass.default_user_class.name} First1 Last1 logged in not me"
  end

  it "should render end user details tags" do
    data = EndUser.push_target 'test1@test.dev', :first_name => 'First1', :last_name => 'Last1', :salutation => 'Mr.', :gender => 'm', :cell_phone => '555-555-5555'
    address = data.build_address :zip => '55555'
    address.end_user_id = data.id
    address.save.should be_true

    address = data.build_work_address :zip => '66666'
    address.end_user_id = data.id
    address.save.should be_true

    @output = @feature.parse_inline("<cms:user><cms:user_id/> <cms:salutation/> <cms:name/> <cms:profile/> <cms:profile_name/> <cms:first_name/> <cms:last_name/> <cms:male>man</cms:male><cms:female>woman</cms:female> <cms:myself>it is me</cms:myself><cms:not_myself>not me</cms:not_myself> <cms:email/> <cms:cell_phone/> <cms:img/> <cms:second_img/> <cms:fallback_img/> <cms:address><cms:zip/></cms:address> <cms:work_address><cms:zip/></cms:work_address></cms:user>") do |c|
      c.expansion_tag('user') { |t| t.locals.user = data }
      c.user_details_tags('user') { |t| t.locals.user }
    end
    @output.should == "1 Mr. First1 Last1 #{UserClass.default_user_class_id} #{UserClass.default_user_class.name} First1 Last1 man not me test1@test.dev 555-555-5555    55555 66666"
  end

  it "should render end user tags" do
    data = EndUser.push_target 'test1@test.dev', :first_name => 'First1', :last_name => 'Last1'

    @output = @feature.parse_inline("<cms:user><cms:name/> <cms:profile/> <cms:profile_name/> <cms:first_name/> <cms:last_name/> <cms:logged_in>logged in</cms:logged_in><cms:not_logged_in>logged out</cms:not_logged_in> <cms:myself>it is me</cms:myself><cms:not_myself>not me</cms:not_myself></cms:user>") do |c|
      c.user_tags('user') { |t| data }
    end
    @output.should == "First1 Last1 #{UserClass.default_user_class_id} #{UserClass.default_user_class.name} First1 Last1 logged in not me"
  end

  it "should render address tag" do
    data = EndUser.push_target 'test1@test.dev'
    address = data.build_address :address => '1 test lane', :address_2 => 'suite 2', :company => 'webiva', :phone => '555-555-5551', :fax => '555-555-5552', :city => 'Boston', :state => 'MA', :zip => '55555', :country => 'United States', :first_name => 'First1', :last_name => 'Last1'
    address.end_user_id = data.id
    address.save.should be_true

    @output = @feature.parse_inline("<cms:address><cms:company/>\n<cms:address:address/>\n<cms:address_2/>\n<cms:city/>, <cms:state/> <cms:zip/> <cms:country/></cms:address>") do |c|
      c.expansion_tag('address') { |t| t.locals.address = address }
      c.user_address_tags('address') { |t| t.locals.address }
    end
    @output.should == "webiva\n1 test lane\nsuite 2\nBoston, MA 55555 United States"
  end

  it "should render image tag" do
    fdata = fixture_file_upload("files/rails.png",'image/png')
    image = DomainFile.create(:filename => fdata)

    @output = @feature.parse_inline("<cms:image/>") do |c|
      c.image_tag('image') { |t| image }
    end

    @output.should have_tag('img', :src => image.url, :width => image.width, :height => image.height)
  end

  it "should render image src" do
    fdata = fixture_file_upload("files/rails.png",'image/png')
    image = DomainFile.create(:filename => fdata)

    @output = @feature.parse_inline("<cms:image field='src'/>") do |c|
      c.image_tag('image') { |t| image }
    end

    @output.should == image.url
  end

  it "should render image width" do
    fdata = fixture_file_upload("files/rails.png",'image/png')
    image = DomainFile.create(:filename => fdata)

    @output = @feature.parse_inline("<cms:image field='width'/>") do |c|
      c.image_tag('image') { |t| image }
    end

    @output.should == image.width.to_s
  end

  it "should render image height" do
    fdata = fixture_file_upload("files/rails.png",'image/png')
    image = DomainFile.create(:filename => fdata)

    @output = @feature.parse_inline("<cms:image field='height'/>") do |c|
      c.image_tag('image') { |t| image }
    end

    @output.should == image.height.to_s
  end

  it "should render image dimensions" do
    fdata = fixture_file_upload("files/rails.png",'image/png')
    image = DomainFile.create(:filename => fdata)

    @output = @feature.parse_inline("<cms:image field='dimensions'/>") do |c|
      c.image_tag('image') { |t| image }
    end

    @output.should == "width='#{image.width}' height='#{image.height}'"
  end

  it "should render image tag align left" do
    fdata = fixture_file_upload("files/rails.png",'image/png')
    image = DomainFile.create(:filename => fdata)

    @output = @feature.parse_inline("<cms:image align='left' border='1'/>") do |c|
      c.image_tag('image') { |t| image }
    end

    @output.should have_tag('img', :src => image.url, :width => image.width, :height => image.height, :style => 'margin: 0 1px 1px 0px')
  end

  it "should render image tag align right" do
    fdata = fixture_file_upload("files/rails.png",'image/png')
    image = DomainFile.create(:filename => fdata)

    @output = @feature.parse_inline("<cms:image align='right' border='1'/>") do |c|
      c.image_tag('image') { |t| image }
    end

    @output.should have_tag('img', :src => image.url, :width => image.width, :height => image.height, :style => 'margin: 0 0 1px 1px')
  end

  it "should render a form tag" do
    frm = mock
    @output = @feature.parse_inline("<cms:search><input type='text' name='q'></cms:search>") do |c|
      c.define_form_tag(frm, 'search')
    end

    @output.should have_tag('form', :method => 'post')
    @output.should have_tag('input', :type => 'text', :name => 'q')
  end

  it "should render the input tag only" do
    search = mock :q => 'test'
    @output = @feature.parse_inline("<cms:search><input type='text' name='q'></cms:search>") do |c|
      c.fields_for_tag('search', :search) { |t| search }
    end

    @output.should_not have_tag('form', :method => 'post')
    @output.should have_tag('input', :type => 'text', :name => 'q')
  end

  it "should render a form errors" do
    user = EndUser.push_target('test@test.dev')
    user.errors.add(:first_name)
    @output = @feature.parse_inline("<cms:user><cms:errors><p><cms:value/></p></cms:errors></cms:user>") do |c|
      c.form_for_tag('user', :user) { |t| user }
      c.form_error_tag('user:errors')
    end

    @output.should have_tag('form', :method => 'post')
    @output.should have_tag('p', :text => 'First name is invalid')
  end

  it "should render a form button tag" do
    user = EndUser.push_target('test@test.dev')
    @output = @feature.parse_inline("<cms:user><cms:submit/></cms:user>") do |c|
      c.form_for_tag('user', :user) { |t| user }
      c.button_tag('submit')
    end

    @output.should have_tag('form', :method => 'post')
    @output.should have_tag('input', :type => 'submit')
  end

  it "should render a form button image tag" do
    user = EndUser.push_target('test@test.dev')
    @output = @feature.parse_inline("<cms:user><cms:submit type='image'>/go.gif</cms:submit></cms:user>") do |c|
      c.form_for_tag('user', :user) { |t| user }
      c.button_tag('submit')
    end

    @output.should have_tag('form', :method => 'post')
    @output.should have_tag('input', :type => 'image', :src => '/go.gif')
  end

  it "should render a form delete button tag" do
    user = EndUser.push_target('test@test.dev')
    @output = @feature.parse_inline("<cms:user><cms:submit>Delete me</cms:submit></cms:user>") do |c|
      c.form_for_tag('user', :user) { |t| user }
      c.delete_button_tag('submit')
    end

    @output.should have_tag('form', :method => 'post')
    @output.should have_tag('input', :type => 'hidden', :name => 'user_delete', :value => '0')
    @output.should have_tag('input', :type => 'submit', :value => 'Delete me')
  end

  it "should render a form submit tag" do
    user = EndUser.push_target('test@test.dev')

    @output = @feature.parse_inline("<cms:user><cms:submit/></cms:user>") do |c|
      c.form_for_tag('user', :user) { |t| user }
      c.submit_tag('submit')
    end

    @output.should have_tag('form', :method => 'post')
    @output.should have_tag('input', :type => 'submit', :value => 'Submit')

    @output = @feature.parse_inline("<cms:user><cms:submit/></cms:user>") do |c|
      c.form_for_tag('user', :user) { |t| user }
      c.submit_tag('submit', :default => 'Press me')
    end

    @output.should have_tag('form', :method => 'post')
    @output.should have_tag('input', :type => 'submit', :value => 'Press me')
  end

  it "should render a form submit tag with expansion" do
    user = EndUser.push_target('test@test.dev')

    @output = @feature.parse_inline("<cms:user><cms:submit>Press me</cms:submit></cms:user>") do |c|
      c.form_for_tag('user', :user) { |t| user }
      c.submit_tag('submit')
    end

    @output.should have_tag('form', :method => 'post')
    @output.should have_tag('input', :type => 'submit', :value => 'Press me')

    @output = @feature.parse_inline("<cms:user><cms:submit type='image'>/go.gif</cms:submit></cms:user>") do |c|
      c.form_for_tag('user', :user) { |t| user }
      c.submit_tag('submit')
    end

    @output.should have_tag('form', :method => 'post')
    @output.should have_tag('input', :type => 'image', :src => '/go.gif')
  end

  it "should render a form submit tag with form" do
    @output = @feature.parse_inline("<cms:submit>Press me</cms:submit>") do |c|
      c.submit_tag('submit', :form => '/go_here')
    end

    @output.should have_tag('form', :action => '/go_here', :method => 'get')
    @output.should have_tag('input', :type => 'submit', :value => 'Press me')
  end

  it "should render a form field tag" do
    user = EndUser.push_target('test@test.dev')

    @output = @feature.parse_inline("<cms:user><cms:first_name/></cms:user>") do |c|
      c.form_for_tag('user', :user) { |t| user }
      c.field_tag('first_name')
    end

    @output.should have_tag('form', :method => 'post')
    @output.should have_tag('input', :type => 'text', :value => '')
  end

  it "should render a form select tag" do
    user = EndUser.push_target('test@test.dev')

    @output = @feature.parse_inline("<cms:user><cms:introduction/></cms:user>") do |c|
      c.form_for_tag('user', :user) { |t| user }
      c.form_field_tag('introduction', :control => 'select') { |t| ['Mr.','Mrs.','Ms.'] }
    end

    @output.should have_tag('form', :method => 'post')
    @output.should have_tag('select', :name => 'introduction')
    @output.should have_tag('option', :name => 'Mr.')
    @output.should have_tag('option', :name => 'Mrs.')
    @output.should have_tag('option', :name => 'Ms.')
  end

  it "should render results and pagelist tags" do

    total_results = 50
    per_page = 10
    page = 2
    offset = (page - 1) * per_page
    pages = {
      :pages => (total_results.to_f / per_page.to_f).ceil,
      :page => page,
      :total => total_results,
      :per_page => per_page,
      :first => offset+1,
      :last => offset + per_page
    }

    @output = @feature.parse_inline("<cms:results><p><cms:first_result/> <cms:last_result/> <cms:total_results/></p><cms:pages/></cms:results>") do |c|
      c.expansion_tag('results') { |t| t.locals.results = pages }
      c.define_results_tags('results') { |t| t.locals.results }
    end

    @output.should have_tag('p', :text => "#{offset+1} #{offset+per_page} #{total_results}")
    @output.should have_tag('a', :href => "?page=1", :text => '1')
    @output.should have_tag('b', :text => '2')
    @output.should have_tag('a', :href => "?page=3", :text => '3')
  end

  it "should render a loop tag's position elements" do
    data = [mock(:first_name => 'First1', :last_name => 'Last1', :email => 'test1@test.dev'),
            mock(:first_name => 'First2', :last_name => 'Last2', :email => 'test2@test.dev'),
            mock(:first_name => 'First3', :last_name => 'Last3', :email => 'test3@test.dev')]

    @output = @feature.parse_inline("<cms:contacts><cms:contact><cms:index/> <cms:at index='0'>at 0</cms:at> <cms:not_at index='0'>not at 0</cms:not_at> <cms:first>first</cms:first> <cms:last>last</cms:last> <cms:not_first>not first</cms:not_first> <cms:not_last>not last</cms:not_last> <cms:middle>middle</cms:middle> <cms:not_middle>not middle</cms:not_middle> <cms:multiple offset='2' value='3'>multiple</cms:multiple> <cms:odd>odd</cms:odd> <cms:even>even</cms:even></cms:contact></cms:contacts>") do |c|
      c.loop_tag('contact') { |t| data }
      c.attribute_tags('contact', %w(first_name last_name email)) { |t| t.locals.contact }
    end

    @output.should == "1  not at 0 first   not last  not middle multiple odd 2  not at 0   not first not last middle    even3  not at 0  last not first   not middle  odd "
  end

  it "should render a post button tag" do
    @output = @feature.parse_inline("<cms:button>Press me</cms:button>") do |c|
      c.post_button_tag('button') { |t| '/go_here' }
    end

    @output.should have_tag('form', :action => "/go_here", :method => 'post')
    @output.should have_tag('input', :type => 'submit', :value => 'Press me')

    @output = @feature.parse_inline("<cms:button type='image'>/go.gif</cms:button>") do |c|
      c.post_button_tag('button') { |t| '/go_here' }
    end

    @output.should have_tag('form', :action => "/go_here", :method => 'post')
    @output.should have_tag('input', :type => 'image', :src => '/go.gif')
  end

  it "should render a login block" do
    user = EndUser.new

    @output = @feature.parse_inline("<cms:login_box><cms:error><p>Login failed.</p></cms:error><cms:form><cms:email/><br/><cms:password/><br/><cms:button>Login</cms:button></cms:form></cms:login_box><cms:no_login_box><p>Welcome</p></cms:no_login_box>") do |c|
      c.login_block('login_box', false) { user }
    end

    @output.should have_tag('form', :method => 'post')
    @output.should have_tag('input', :type => 'text', :name => 'login[email]')
    @output.should have_tag('input', :type => 'password', :name => 'login[password]')
    @output.should have_tag('input', :type => 'submit', :value => 'Login')
    @output.should_not have_tag('p', :text => 'Login failed.')

    @output = @feature.parse_inline("<cms:login_box><cms:error><p>Login failed.</p></cms:error><cms:form><cms:email/><br/><cms:password/><br/><cms:button>Login</cms:button></cms:form></cms:login_box><cms:no_login_box><p>Welcome</p></cms:no_login_box>") do |c|
      c.login_block('login_box', true) { user }
    end

    @output.should have_tag('form', :method => 'post')
    @output.should have_tag('input', :type => 'text', :name => 'login[email]')
    @output.should have_tag('input', :type => 'password', :name => 'login[password]')
    @output.should have_tag('input', :type => 'submit', :value => 'Login')
    @output.should have_tag('p', :text => 'Login failed.')

    user = EndUser.push_target('test@test.dev')

    @output = @feature.parse_inline("<cms:login_box><cms:error><p>Login failed.</p></cms:error><cms:form><cms:email/><br/><cms:password/><br/><cms:button>Login</cms:button></cms:form></cms:login_box><cms:no_login_box><p>Welcome</p></cms:no_login_box>") do |c|
      c.login_block('login_box', true) { user }
    end

    @output.should have_tag('p', :text => 'Welcome')
    @output.should_not have_tag('form')
  end

  describe "Media Tags" do
    before(:each) do
      mod = SiteModule.activate_module(Domain.find(DomainModel.active_domain_id),'media')
      mod.update_attributes(:status => 'active')

      opts = {}
      @options = Media::AdminController.module_options
      @options.media_video_handler = @options.media_video_handlers[0][1]
      @options.media_audio_handler = @options.media_audio_handlers[0][1]
      Configuration.set_config_model(@options)
    end

    
    
    it "should render media flv" do
      fdata = fixture_file_upload("files/fake_video.flv", 'video/flv')
      media = DomainFile.create(:filename => fdata)

      @output = @feature.parse_inline("<cms:media/>") do |c|
        c.media_tag('media') { |t| media }
      end

      @output.should have_tag('div', :id => 'video_')
      @output.should have_tag('script')

      media.destroy
    end

    it "should render media mp3" do
      fdata = fixture_file_upload("files/fake_audio.mp3", 'audio/mp3')
      media = DomainFile.create(:filename => fdata)

      @output = @feature.parse_inline("<cms:media/>") do |c|
        c.media_tag('media') { |t| media }
      end

      @output.should have_tag('p', :id => 'audio_')
      @output.should have_tag('script')

      media.destroy
    end

    it "should render media mov" do
      fdata = fixture_file_upload("files/fake_movie.mov", 'video/quicktime')
      media = DomainFile.create(:filename => fdata)

      @output = @feature.parse_inline("<cms:media/>") do |c|
        c.media_tag('media') { |t| media }
      end

      @output.should have_tag('embed')

      media.destroy
    end
  end

  describe "Captcha Tags" do
    before(:each) do
      mod = SiteModule.activate_module(Domain.find(DomainModel.active_domain_id),'feedback')
      mod.update_attributes(:status => 'active')

      Configuration.options.captcha_handler = 'feedback_captcha'
    end

    it "should render captcha tag" do
      controller = mock :session => {}, :params => {}, :myself => EndUser.default_user
      controller.should_receive(:render_to_string)
      @captcha = WebivaCaptcha.new controller

      @output = @feature.parse_inline("<cms:captcha/>") do |c|
        c.captcha_tag('captcha') { |t| @captcha }
      end

    end
  end
end
