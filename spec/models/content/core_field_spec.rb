require File.dirname(__FILE__) + "/../../spec_helper"
require File.dirname(__FILE__) + "/../../content_spec_helper"

describe Content::Field do

  reset_domain_tables :content_models,:content_model_fields
  
  include ContentSpecHelper
  
  before(:each) do
    connect_to_migrator_database
    @cm = create_spec_test_content_model
  end
  
  
  describe "Should be able to create one of each different type of field" do
    
    it "should be able to create a string field and display the value" do
      
      field = ContentModelField.new(:name => 'Title',:field_type => 'string',:field_module => 'content/core_field',:field_options => { :required => true })
      
      @cm.update_table([ field.attributes ])
      
      cls = @cm.content_model # Get the content model
      
      cls.count.should == 0 # Should have nothing in the table
      
      obj = cls.create(:title => 'Test Title') # Create a new row, set the title
      
      cls.count.should == 1 
      obj.title.should == 'Test Title'
      
      obj.class.columns[1].type.should == :string
      
      @cm.reload
      @cm.content_model_fields[0].content_display(obj).should == "Test Title" # Display the title
      
      
      obj = cls.create() # Title field is required, so this shouldn't work
      obj.should_not be_valid
      
    end
    
    it "should be able to create a content model with the remaining core field types" do
      fields = Content::CoreField.fields
      
      cmfs = []
      
      field_opts = { :options => { :options => "one;;a\ntwo;;b" },
                    :multi_select => { :options => "option 1;;a\noption 2;;b\noption 3;;c" }
                   }
      
      fields.each do |fld|
        cmfs << ContentModelField.new(:name => "#{fld[:name]} Field",:field_type => fld[:name], :field_module => 'content/core_field',
                                      :field_options => field_opts[fld[:name]] || {}  ).attributes
      end
      
      @cm.update_table(cmfs)
      
      @cm.reload
      
      # We should have ID + all the fields we tried to add in
      @cm.content_model.columns.length.should == (cmfs.length + 1) 
      
      fdata = fixture_file_upload("files/rails.png",'image/png')
      @image_file = DomainFile.create(:filename => fdata)
      
      fdata = fixture_file_upload("files/test.txt",'text/plain')
      @doc_file = DomainFile.create(:filename => fdata)
      

      # Ok, so I'm very well aware that this is a little complicated for a test
      # But with all the core types, I think it's for the best (and I'm lazy)
      
      # Dummy Values for each of the fields we created
      # :field_name => value (both assignment and display) or
      # :field_name => [ assigned value, display value ]
      dummy_values = { :string_field => [ '<h1>Test String</h1>', '&lt;h1&gt;Test String&lt;/h1&gt;' ],
                        :html_field => "<h1>Test Header</h1><p>Yo!</p>",
                        :editor_field =>  "<h1>Test Header</h1><p>Yo!</p>",
                        :email_field => "test@webiva.org",
                        :image_field_id => [ @image_file.id,@image_file.image_tag ],
                        :document_field_id => [ @doc_file.id,@doc_file.name ],
                        :options_field => [ 'a','one' ],
                        :us_state_field => 'MA',
                        :multi_select_field => [ ['a','c' ], 'option 1, option 3' ],
                        :integer_field => [ 431212513, '431212513' ],
                        :currency_field => [ 3.14111111, '3.14' ],
                        :date_field => [ Time.mktime(2009,6,12), "06/12/2009" ],
                        :datetime_field => [ Time.mktime(2009,6,12,5,5), "06/12/2009 05:05 AM" ]
                     }

      dummy_values[:text_field] = <<-EOF
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec pulvinar molestie ipsum, sed blandit elit luctus ut. Curabitur sed purus in magna lobortis dignissim. Sed varius felis condimentum nisl sodales in pharetra libero posuere. Nunc dictum, justo a tincidunt rhoncus, metus sem facilisis odio, id iaculis lectus nunc id mi. Ut egestas, diam et ultricies viverra, augue nulla lacinia leo, a rhoncus massa eros et risus. Maecenas condimentum, purus nec rutrum blandit, arcu ligula viverra quam, sit amet feugiat diam metus et odio. Nunc lacinia tellus quis leo viverra volutpat. Sed erat nisi, cursus ut tristique in, scelerisque id sem. Vestibulum vulputate, lectus quis elementum rutrum, diam neque vehicula nibh, at malesuada urna est et nisi. In non diam vel augue mollis accumsan eu a urna. Donec congue dui vel massa pharetra sollicitudin.
      EOF
      
      cls = @cm.content_model
      entry = cls.new
      dummy_values.each { |field,val| entry.send("#{field}=",val.is_a?(Array) ? val[0] : val) } # assign the dummy value to each field
      
      entry.save.should be_true # Make sure we can save
      
      entry.reload # Make sure everything is coming from the DB
      
      @cm.content_model_fields.each do |fld|
        if dummy_values[fld.name.to_sym]
          val = dummy_values[fld.field.to_sym]
          if fld.content_display(entry) != (val.is_a?(Array) ? val[1] : val)
            raise "#{fld.name} does not match expected value: '#{fld.content_display(entry)}', '#{(val.is_a?(Array) ? val[1] : val)}' "
          end
        end        
      end
      
      @image_file.destroy
      @doc_file.destroy
    end
  
    
  
  end
  

  
end
