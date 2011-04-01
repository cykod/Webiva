

module ContentSpecHelper

  def connect_to_migrator_database
     # Switch to migrator
    @defaults_config_file = YAML.load_file("#{Rails.root}/config/defaults.yml")

    dmn = Domain.find(@defaults_config_file['testing_domain']).get_info
    DomainModel.activate_database(dmn,'migrator',false)

    # Kill the spec test table if no-go
  end

  def create_spec_test_content_model(args={ })
    ContentModel.connection.execute('DROP TABLE IF EXISTS cms_spec_tests')  
    cm = ContentModel.create({:name => 'spec_test'}.merge(args))
    cm.create_table # Create the table    
    cm
  end
  
  def create_dummy_fields(cm,create_fields = [ :string ] )
      fields = Content::CoreField.fields
      
      cmfs = []
      
      field_opts = { :options => { :options => "one;;a\ntwo;;b" },
                    :multi_select => { :options => "option 1;;a\noption 2;;b\noption 3;;c" }
                   }
      
      if !create_fields
        fields.each_with_index do |fld,idx|
          cmfs << ContentModelField.new(:name => "#{fld[:name]} Field",:field_type => fld[:name], :field_module => 'content/core_field', :position => idx+1,
                                      :field_options => field_opts[fld[:name]] || {}  ).attributes
        end  
      else 
        create_fields.each_with_index do |fld_name,idx|
          fld = fields.detect { |fld_info| fld_info[:name] == fld_name.to_sym }
          if !create_fields || create_fields.include?(fld[:name])
            cmfs << ContentModelField.new(:name => "#{fld[:name]} Field",:field_type => fld[:name], :field_module => 'content/core_field', :position => idx+1,
                                        :field_options => field_opts[fld[:name]] || {}  ).attributes
          end
        end  
      end
      
      cm.update_table(cmfs)
      cm.reload
      
      cm
   end
  
  def create_content_model_with_all_fields(opts={})
    ContentModel.connection.execute('DROP TABLE IF EXISTS cms_controller_spec_tests')

    @cm = ContentModel.create({:name => 'controller_spec_test', :show_on_content => true}.merge(opts))
    @cm.create_table # Create the table
    
    fields = Content::CoreField.fields
      
    cmfs = []
    field_opts = {
      :options => { :options => "one;;a\ntwo;;b" },
      :multi_select => { :options => "option 1;;a\noption 2;;b\noption 3;;c" }
    }
      
    fields.each do |fld|
      cmfs << ContentModelField.new(:name => "#{fld[:name]} Field",
                                    :field_type => fld[:name],
                                    :field_module => 'content/core_field',
                                    :field_options => field_opts[fld[:name]] || {}
                                    ).attributes
    end

    @cm.update_table(cmfs)
    @cm.reload
  end
  
  def self.setup_content_model_test_with_all_fields(spec)
    spec.before(:all) do
      create_content_model_with_all_fields
    
      %w(content_models content_model_fields).each do |table|
        DomainModel.__skip_table table
      end
    end
  
    spec.after(:all) do
      DomainModel.__clear_skip_table
      %w(content_models content_model_fields).each do |table|
        DomainModel.__add_modified_table table
      end
      DomainModel.__truncate_modified_tables
      ContentModel.connection.execute('DROP TABLE IF EXISTS cms_controller_spec_tests')
    end

    spec.before(:each) do
      @cm = ContentModel.find @cm.id
    end
  end
end
