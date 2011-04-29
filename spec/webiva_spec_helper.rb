# Stolen shamelessly from DataBaseCleaner gem - modified to not kill the main Webiva tables
# but only the domain model tables
class WebivaCleaner

    def start
      if DomainModel.connection.respond_to?(:increment_open_transactions)
        DomainModel.connection.increment_open_transactions
      else
        DomainModel.__send__(:increment_open_transactions)
      end

      DomainModel.connection.begin_db_transaction
    end


    def clean
      DomainModel.connection.rollback_db_transaction

      if DomainModel.connection.respond_to?(:decrement_open_transactions)
        DomainModel.connection.decrement_open_transactions
      else
        DomainModel.__send__(:decrement_open_transactions)
      end
    end

    def connection
      DomainModel.connection
    end

    def tables_to_truncate
       connection.tables -  %w(component_schemas schema_migrations)
    end

    def truncate_table(table_name)
      connection.execute("TRUNCATE TABLE #{connection.quote_table_name(table_name)};")
    end

    def reset
      connection.disable_referential_integrity do
        tables_to_truncate.each do |table_name|
          truncate_table table_name
        end
      end
    end

    def self.cleaner
      @@cleaner ||= WebivaCleaner.new
    end

end

class WebivaSystemCleaner
  def connection
    SystemModel.connection
  end

  def tables_to_truncate
    connection.tables -  %w(schema_migrations globalize_countries globalize_languages globalize_translations)
  end

  def truncate_table(table_name)
    connection.execute("TRUNCATE TABLE #{connection.quote_table_name(table_name)};")
  end

  def save_test_domain
    result = connection.execute("SELECT * FROM domains WHERE id = #{CMS_DEFAULTS['testing_domain']}")
    @domain = {}
    result.each_hash { |row| @domain = row }

    @domain_database = {}
    result = connection.execute("SELECT * FROM domain_databases WHERE id = #{@domain['domain_database_id']}")
    result.each_hash { |row| @domain_database = row }
  end

  def create_test_domain
    connection.execute("INSERT INTO clients (name, domain_limit, max_client_users, max_file_storage) VALUES('Webiva', 10, 10, #{100.gigabytes/1.megabyte})")
    connection.execute("INSERT INTO client_users (client_id, username, hashed_password, client_admin, system_admin) VALUES(1, 'admin', 'invalid', 1, 1)")
    database_name = @domain_database['name']
    connection.execute("INSERT INTO domains (id, name, `database`, client_id, status, file_store, domain_database_id, created_at, updated_at) VALUES(#{CMS_DEFAULTS['testing_domain']}, '#{@domain['name']}', '#{database_name}', 1, 'initialized', 3, 1, NOW(), NOW())")
    connection.execute("INSERT INTO domain_databases (client_id, name, `options`, max_file_storage) VALUES(1, '#{database_name}', '#{@domain_database['options']}', #{10.gigabytes/1.megabyte})")
  end

  def reset
    save_test_domain

    connection.disable_referential_integrity do
      tables_to_truncate.each do |table_name|
        truncate_table table_name
      end
    end

    create_test_domain
  end

  def self.cleaner
    @@cleaner ||= WebivaSystemCleaner.new
  end
end

class DomainModel
  @@skip_modified_tables = {}
  @@modified_tables = {}
  def self.__reset_modified_tables
    @@modified_tables = {}
  end
  
  def self.__skip_table(table)
    @@skip_modified_tables[table] = table
  end

  def self.__clear_skip_table
    @@skip_modified_tables = {}
  end

  def self.__add_modified_table(table)
    @@modified_tables[table] = table
  end

  def self.__truncate_modified_tables
    DomainModel.connection.reconnect! unless DomainModel.connection.active?
    @@modified_tables.each do |table, val|
      next if table == 'component_schemas'
      next if @@skip_modified_tables[table]
      next if table =~ /^cms_/ && ! DomainModel.connection.table_exists?(table)
      DomainModel.connection.execute("TRUNCATE #{table}")
      UserClass.create_built_in_classes if table == 'user_classes'
    end
    DomainModel.__reset_modified_tables
  end

  before_create :__add_table
  def __add_table
    DomainModel.__add_modified_table self.class.table_name
  end
end

class SystemModel
  @@system_tables = {
    'clients' => [1],
    'client_users' => [1],
    'domain_databases' => [1],
    'domains' => [CMS_DEFAULTS['testing_domain']]
  }

  @@modified_tables = {}
  def self.__reset_modified_tables
    @@modified_tables = {}
  end
  
  def self.__add_modified_table(table)
    @@modified_tables[table] = table
  end

  def self.__truncate_modified_tables
    SystemModel.connection.reconnect! unless SystemModel.connection.active?
    @@modified_tables.each do |table, val|
      next if table == 'schema_migrations'
      if @@system_tables[table]
        SystemModel.connection.execute("DELETE FROM #{table} WHERE id NOT IN(#{@@system_tables[table].join(',')})")
      else
        SystemModel.connection.execute("TRUNCATE #{table}")
      end
    end
    SystemModel.__reset_modified_tables
  end

  before_create :__add_table
  def __add_table
    SystemModel.__add_modified_table self.class.table_name
  end
end

# http://gensym.org/2007/10/18/rspec-on-rails-tip-weaning-myself-off-of-fixtures
# Wean ourselves off of fixtures
# Call this within the description (e.g., after the describe block) to remove everything from the associated class or table
# Changed so that we're modifying DomainModel tables

def reset_domain_tables(*tables)
end

def reset_system_tables(*tables)
end

def transaction_reset
  before(:each)  {  
    DomainFile.root_folder
    UserClass.create_built_in_classes
    SiteVersion.default
    WebivaCleaner.cleaner.start }
  after(:each) {  WebivaCleaner.cleaner.clean }
end

# Activate a module in a test (force the activation) so you can use handlers etc.
def test_activate_module(name,options = nil)
  mod = SiteModule.activate_module(Domain.find(DomainModel.active_domain_id),name.to_s,:force => true)
  mod.update_attributes(:status => 'active')

  if options
    mod_options = "#{name.to_s.classify}::AdminController".constantize.module_options(options)
    Configuration.set_config_model(mod_options)
  end

end

def renderer_builder(name,&block)
  parts = name.split("/")

  define_method("#{parts[-1]}_renderer_helper") do |opts,conns|
    if block
      opt_opts = yield
      opts = opt_opts.merge(opts)
    end
    build_renderer("/#{parts[1]}",name,opts,conns)
  end
  
  class_eval <<-METHOD
   def #{parts[-1]}_renderer(opts={},conns={})
      #{parts[-1]}_renderer_helper(opts,conns)
   end
  METHOD


end

def add_factory_girl_path(dir)
  if !Factory.definition_file_paths.include?(dir)
    Factory.definition_file_paths <<  dir
    Factory.definition_file_paths.uniq!
    Factory.find_definitions
  end
end

def renderer_builder(name,&block)
  parts = name.split("/")

  define_method("#{parts[-1]}_renderer_helper") do |opts,conns|
    if block
      opt_opts = yield
      opts = opt_opts.merge(opts)
    end
    build_renderer("/#{parts[1]}",name,opts,conns)
  end
  
  class_eval <<-METHOD
   def #{parts[-1]}_renderer(opts={},conns={})
      #{parts[-1]}_renderer_helper(opts,conns)
   end
  METHOD


end

def add_factory_girl_path(dir)
  if !Factory.definition_file_paths.include?(dir)
    Factory.definition_file_paths <<  dir
    Factory.definition_file_paths.uniq!
    Factory.find_definitions
  end
end

ActiveSupport::TestCase.fixture_path = RAILS_ROOT + '/spec/fixtures/'


# Custom Matchers
class HandleActiveTableMatcher
  def initialize(table_name,&block)
    @table_name = table_name
    @block = block
    @error_msgs = []
  end
  
  def matches?(controller,&block)
    @block ||= block # Could be passed in via the match func instead of initialization

    @controller = controller
    
    @cols = controller.send("#{@table_name}_columns",{})

    usr = @controller.send(:myself)
    @error_msgs << "User is not an editor - use mock_editor to make handle_active_table work" if !usr.editor?
    
    # Go through each column
    @cols.each do |header|
      # Try a search
      if header.is_searchable?
        args = HashWithIndifferentAccess.new({ @table_name => { header.field_hash => header.dummy_search, :display => { header.field_hash => 1 } } })
        begin
          @block.call(args)
        rescue Mysql::Error, ActiveRecord::StatementInvalid  => e
          @error_msgs << "Error searching on '#{header.field}' (#{e.to_s})"
        end
      end
      
      if header.is_orderable?
        begin
          @block.call(args)
        rescue Mysql::Error, ActiveRecord::StatementInvalid  => e
          @error_msgs << "Error ordering on '#{header.field}' (#{e.to_s})"
        end
      end
    end
    
    @error_msgs.length == 0
  end
  
  def description
    "handle active table #{@table_name}"
  end
  
  def failure_message
    " active table #{@table_name} did not operate properly: " + @error_msgs.join(",")
  end
end

def handle_active_table(table_name,&block)
  HandleActiveTableMatcher.new(table_name,&block)
end

def activate_module(name,options={})
  mod = SiteModule.activate_module(Domain.find(DomainModel.active_domain_id),name, :force => true)
  mod.update_attributes(:status => 'active', :options => options.to_hash)
end

module RspecRendererExtensions
 def renderer_feature_data=(val); @renderer_feature_data = val; end
 def renderer_feature_data; @renderer_feature_data; end
 
 def should_render_feature(feature_name)
   renderer = self
   expt = renderer.should_receive("#{feature_name}_feature") do |*feature_data|
     if feature_data.length == 0
      renderer.renderer_feature_data = renderer.instance_variable_hash
     else
      renderer.renderer_feature_data = feature_data[0]
     end
     "WEBIVA FEATURE OUTPUT"
   end
   expt
 end


end

module Spec
 module Rails
  module Example
    class ModelExampleGroup
     
      
      def mock_editor(email = 'test@webiva.com',permissions = nil)
        # get me a client user to ignore any permission issues    
        @myself = EndUser.push_target('test@webiva.com')

        if permissions.nil?
          @myself.user_class = UserClass.client_user_class
          @myself.client_user_id = 1
          @myself.save
        else
          @myself.user_class = UserClass.domain_user_class
          @myself.save
          permissions = [ permissions ] unless permissions.is_a?(Array)
          permissions.map! { |perm| perm.to_sym } 
          
          permissions.each do |perm|
            @myself.user_class.has_role(perm)
          end
        end
        @myself
      end
      
      def mock_user(email = 'test@webiva.com')
        # get me a client user to ignore any permission issues    
        @myself = EndUser.push_target(email)
      end
    end

    class ControllerExampleGroup < FunctionalExampleGroup
 

      def mock_editor(email = 'test@webiva.com',permissions = nil)
        # get me a client user to ignore any permission issues    
        @myself = EndUser.push_target('test@webiva.com')

        if permissions.nil?
          @myself.user_class = UserClass.client_user_class
          @myself.client_user_id = 1
          @myself.save
        else
          @myself.user_class = UserClass.domain_user_class
          @myself.save
          permissions = [ permissions ] unless permissions.is_a?(Array)
          permissions.map! { |perm| perm.to_sym } 
          
          permissions.each do |perm|
            @myself.user_class.has_role(perm)
          end
        end
        
        controller.should_receive('myself').at_least(:once).and_return(@myself)
      end
      
      def mock_user(email = 'test@webiva.com')
        # get me a client user to ignore any permission issues    
        @myself = EndUser.push_target(email)
        controller.should_receive('myself').at_least(:once).and_return(@myself)
        @myself
      end

      def paragraph_controller_helper(site_node_path,display_module_type,data={},extra_attributes = {})
        display_parts = display_module_type.split("/")
	@site_version ||= SiteVersion.new :name => 'Test', :default_version => true
	@root_node ||= SiteNode.create :site_version => @site_version, :node_type => 'R', :node_path => '/'
	@site_node = @root_node.add_subpage(site_node_path.sub('/', ''))
	@revision = PageRevision.create :revision_container => @site_node, :language => 'en', :active => true, :created_by => @myself, :updated_by => @myself
	@paragraph = PageParagraph.create :display_module => display_parts[0..-2].join("/"), :display_type => display_parts[-1], :page_revision_id => @revision.id, :data => data, :attributes => extra_attributes
      end

      def paragraph_controller_path
	['page', @site_node.id, @revision.id, @paragraph.id, 0]
      end

      def paragraph_controller_get(page, args = {})
	args[:path] = paragraph_controller_path
	get page, args
      end

      def paragraph_controller_post(page, args = {})
	args[:path] = paragraph_controller_path
	post page, args
      end

      def display_all_editors_for(&block)
	controller.class.get_editor_for.each do |editor|
	  paragraph_controller_helper("/#{editor[0]}", "/#{controller.class.to_s.underscore}/#{editor[0]}")
	  output = paragraph_controller_get editor[0]
	  yield editor[0], output
	end
      end

      def build_renderer_helper(user_class,site_node_path,display_module_type,data={},page_connections={},extra_attributes = {})
        display_parts = display_module_type.split("/")
        para = PageParagraph.create(:display_type => display_parts[-1], :display_module => display_parts[0..-2].join("/"),:data=>data)
        para.attributes = extra_attributes
        para.direct_set_page_connections(page_connections)
        rnd = para.renderer.new(user_class,controller,para,SiteNode.new(:node_path => site_node_path,:site_version_id => SiteVersion.default.id),PageRevision.new,{})
        rnd.extend(RspecRendererExtensions)
        rnd
      end
         
      def build_renderer(site_node_path,display_module_type,data={},page_connections={},extra_attributes={})
        build_renderer_helper(UserClass.default_user_class,site_node_path,display_module_type,data,page_connections,extra_attributes)
      end
      
      def build_anonymous_renderer(site_node_path,display_module_type,data={},page_connections={},extra_attributes={})
        build_renderer_helper(UserClass.anonymous_user_class,site_node_path,display_module_type,data,page_connections,extra_attributes)
      end     

      def renderer_get(rnd,args = {})
        controller.set_test_renderer(rnd)
        get :renderer_test, args
      end
      
      def renderer_post(rnd,args = {})
        controller.set_test_renderer(rnd)
        post :renderer_test, args
      end
      
   end
   
    class ViewExampleGroup < FunctionalExampleGroup
      def build_feature(feature_class,code=nil)
        if code
          site_feature = mock_model(SiteFeature,:body => code,:body_html => code,:feature_type => :any,:options => {} )
          paragraph = mock_model(PageParagraph,:site_feature => site_feature, :content_publication => nil,:page_revision => PageRevision.new, :language => 'en', :html_include => {})
        else
          paragraph = mock_model(PageParagraph,:site_feature => nil, :content_publication => nil,:page_revision => PageRevision.new, :language => 'en', :html_include => {})
        end
        renderer = mock_model(ParagraphRenderer,
                              :get_handler_info => [],
                              :protect_against_forgery? => false,
                              :require_js => nil,
                              :paragraph_action_url => '/paragraph',
                              :html_include => {},
                              :paragraph => paragraph)

        feature_class.classify.constantize.new(paragraph,renderer)
      end
   end   
  end
 end
end


class ParagraphOutputMatcher
  def initialize(output_type,args)
    @output_type = output_type
    @args = args
    @output_args = nil
  end
  
  def matches?(renderer)
    output  = renderer.output
    if @output_type == 'render_feature'
      renderer.renderer_feature_data == @args
    elsif @output_type == 'assign_feature_data' # break this out into a separate matcher
      if renderer.renderer_feature_data && renderer.renderer_feature_data[@args[0].to_sym] == @args[1]
        true
      else 
        @output_type_error = "mis-assigned :#{@args[0]}"
        @output_args = renderer.renderer_feature_data ? renderer.renderer_feature_data[@args[0].to_sym] : nil
        @args = @args[1]
        false
      end
    else
      if output.is_a?(ParagraphRenderer::ParagraphOutput)
        @output_args = output.render_args.clone
        @output_args.delete(:locals) if !@args[:locals]
        if @output_type == 'render'
          @output_args == @args
        else
          @output_type_error = "Renderered"
          false
        end
      elsif output.is_a?(ParagraphRenderer::ParagraphRedirect)
        @output_args = output.args
        if @output_type == 'redirect'
          @output_args == @args
        else
          @output_type_error = "Redirected"
          false
        end
      else
        @output_type_error = "Failed to output anything"
        false
      end
    end
  end
  
  def description
   "Should #{@type.humanize}"
  end
  
  def failure_message
    msg = "Does not match expected renderer output:\n"
    if @output_type_error
      msg << "Expected paragraph to #{@output_type.humanize} instead it #{@output_type_error}\n"
    end
    msg << "Expected:" 
    PP.singleline_pp(@args,msg)
    msg << "\nReceived:"
    PP.singleline_pp(@output_args,msg)
    msg
  end
end


def render_feature_data(args)
  ParagraphOutputMatcher.new('render_feature',args)
end

def render_paragraph(args)
  ParagraphOutputMatcher.new('render',args)
end

def redirect_paragraph(args)
  ParagraphOutputMatcher.new('redirect',args)
end

def assign_to_feature(elem,data)
  ParagraphOutputMatcher.new('assign_feature_data',[elem,data])
end





# Custom Matchers
class ModelInjectionAttackMatcher
  def initialize(model,test_string="<script>test();</script>",&block)
    @model = model
    @test_string = test_string
    @block = block
    @error_msgs = []
  end
  
  def matches?(feature,&block)
    @block ||= block # Could be passed in via the match func instead of initialization

    @feature = feature
    
    @columns = @model.class.columns
    
    
    # Go through each column
    @columns.each do |col|
      if [:string,:text].include?(col.type)
        @model.send("#{col.name}=",@test_string)
      end
    end
    
    @output = @block.call(@feature,@model)
    
    !@output.include?(@test_string)
  end
  
  def description
    "check for escaping of '#{@test_string}' in argument attributes"
  end
  
  def failure_message
    msg = "  '#{@test_string}' was successfully injected into the output: "
     PP.pp(@output.to_s,msg)
    msg
  end
end

def prevent_feature_injection(model,&block)
  ModelInjectionAttackMatcher.new(model,&block)
end

# No Longer available in ModelTests
def fixture_file_upload(path, mime_type = nil, binary = false)
  fixture_path = ActionController::TestCase.send(:fixture_path) if ActionController::TestCase.respond_to?(:fixture_path)
  ActionController::TestUploadedFile.new("#{fixture_path}#{path}", mime_type, binary)
end

module ActionController
  class TestSession
    def unchanged!; end
  end
end

Spec::Runner.configure do |config|
  # If you're not using ActiveRecord you should remove these
  # lines, delete config/database.yml and disable :active_record
  # in your config/boot.rb
  config.use_transactional_fixtures = false # Modified for 2.3.2
  config.use_instantiated_fixtures  = false
  config.fixture_path = RAILS_ROOT + '/spec/fixtures/'

  tests_are_running_file = "#{Rails.root}/tmp/tests_are_running"
  
  config.before(:suite) do
    if File.exists?(tests_are_running_file)
      WebivaCleaner.cleaner.reset
      WebivaSystemCleaner.cleaner.reset
    end
    File.open(tests_are_running_file, 'w') { |f| }
    UserClass.create_built_in_classes
  end

  config.after(:suite) do
    File.delete tests_are_running_file if File.exists?(tests_are_running_file)
  end

  config.before(:each) do
    DataCache.reset_local_cache
  end

  config.after(:each) do
    DomainModel.__truncate_modified_tables
    SystemModel.__truncate_modified_tables    
  end
end
