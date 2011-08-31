require File.dirname(__FILE__) + "/../spec_helper"
require File.dirname(__FILE__) + "/../content_spec_helper"

describe ContentPublication do

  include ContentSpecHelper

  reset_domain_tables :content_publications,:content_publication_fields, :content_model_features, :content_tags,:content_tag_tags

  ContentSpecHelper.setup_content_model_test_with_all_fields self
   
  describe "dynamic fields" do
  
    it "should be able to fill in the current time with a dynamic field" do
       @publication = @cm.content_publications.create(:name => 'Test Form',:publication_type => 'create',:publication_module => 'content/core_publication')
       
       @publication.content_publication_fields.create(:field_type => 'input',:content_model_field_id => @cm.field(:string_field).id)
       @publication.content_publication_fields.create(:field_type => 'dynamic',:content_model_field_id => @cm.field(:datetime_field).id,
                                                      :data => { :dynamic => 'content/core_field:current' })

       @entry = @cm.content_model.new
       
       now = Time.now 
       
       Time.should_receive(:now).at_least(:once).and_return(now)
       @publication.update_entry(@entry,{ :string_field => 'Test String' },{})    
       
       @entry.datetime_field.should == now
       @entry.string_field.should == 'Test String'
    end
  
  end
  
  describe "preset fields" do
  
    it "should be able to fill in a value with a preset field" do
       @publication = @cm.content_publications.create(:name => 'Test Form',:publication_type => 'create',:publication_module => 'content/core_publication')
       
       @publication.content_publication_fields.create(:field_type => 'preset',:content_model_field_id => @cm.field(:string_field).id, :data => { :preset => 'My Preset Value' })

       @entry = @cm.content_model.new
       @publication.update_entry(@entry,{ :datetime_field => Time.now },{})    
       
       @entry.string_field.should == 'My Preset Value'
    end
  
  end
  
  
  describe 'field filters' do
  
    it "should be able to do a like filter" do
       @publication = @cm.content_publications.create(:name => 'List',:publication_type => 'list',:publication_module => 'content/core_publication')
       @publication.content_publication_fields.create(:field_type => 'value',:content_model_field_id => @cm.field(:string_field).id, :data => { :filter => 'filter' })
       
       @entry1 = @cm.content_model.create(:string_field => 'A Field')
       @entry2 = @cm.content_model.create(:string_field => 'B Field')

       @paging, @data = @publication.get_list_data(1,{:filter_string_field_like => 'Fi'})
       @data.length.should == 2 # Should return both

       
       @paging, @data = @publication.get_list_data(1,{:filter_string_field_like => 'A Fi'})
       @data.length.should == 1 # should return only 'A Field'
       @data[0].string_field.should == 'A Field'
    end
    
    it "should be able to do an empty filter" do
       @publication = @cm.content_publications.create(:name => 'List',:publication_type => 'list',:publication_module => 'content/core_publication')
       @publication.content_publication_fields.create(:field_type => 'value',:content_model_field_id => @cm.field(:string_field).id, :data => { :filter => 'filter'  })
       
       @entry1 = @cm.content_model.create(:text_field => 'Text Field') # Set a different field, not string_field
       @entry2 = @cm.content_model.create(:string_field => 'String Field')
       
       @paging, @data = @publication.get_list_data(1,{:filter_string_field_not_empty => false})
       @data.length.should == 2 # Should return both

       
       @paging, @data = @publication.get_list_data(1,{:filter_string_field_not_empty => true})
       @data.length.should == 1 # should return only 'A Field'
       @data[0].string_field.should == 'String Field'    
    end

    it "should be able to do an date range filter" do
       @publication = @cm.content_publications.create(:name => 'List',:publication_type => 'list',:publication_module => 'content/core_publication')
       @publication.content_publication_fields.create(:field_type => 'value',:content_model_field_id => @cm.field(:datetime_field).id, :data => { :filter => 'filter' })
       
       @entry0 = @cm.content_model.create(:datetime_field => 3.years.ago, :string_field => '3 Years Ago')
       @entry1 = @cm.content_model.create(:datetime_field => 1.hours.ago, :string_field => '1 Hour Ago')
       @entry2 = @cm.content_model.create(:datetime_field => Time.now.at_beginning_of_month - 2.days, :string_field => 'Beginning of the month minus 2 days')
       
       @paging, @data = @publication.get_list_data(1,{:filter_datetime_field_start => 'year_ago' })
       @data.length.should == 2 # Should return all but the first

       
       @paging, @data = @publication.get_list_data(1,{:filter_datetime_field_start => '0_month' })
       @data.length.should == 1 # should return only @entry1
       @data[0].string_field.should == '1 Hour Ago'    
       
       @paging, @data = @publication.get_list_data(1,{:filter_datetime_field_end => '0_month', :filter_datetime_field_start => 'year_ago'  })
       @data.length.should == 1 # should return only '@entry1
       @data[0].string_field.should == 'Beginning of the month minus 2 days'    
       
    end


    describe "Fuzzy filtering and exposed filters"  do

      before(:each) do
        @publication = @cm.content_publications.create(:name => 'List',:publication_type => 'list',:publication_module => 'content/core_publication')

       
        cls = @cm.content_model

        @entry0 = cls.create(:string_field => 'Yes', :text_field => 'Yay!')
        @entry1 = cls.create(:string_field => 'No', :text_field => 'Nay!')
        @entry2 = cls.create(:string_field => 'No', :text_field => 'Yay!')
        @entry3 = cls.create(:string_field => 'Yes', :text_field => 'Nay!')

      end

      it "should be able to do a fuzzy filter" do
        @publication.content_publication_fields.create(:field_type => 'value',:content_model_field_id => @cm.field(:string_field).id, :data => { :filter => 'fuzzy',:fuzzy_filter => 'a'  })
        
        @publication.content_publication_fields.create(:field_type => 'value',:content_model_field_id => @cm.field(:text_field).id, :data => { :filter => 'fuzzy', :fuzzy_filter => 'a'  })

        
        @paging, @data = @publication.get_list_data(1,{:filter_string_field_like => 'No', :filter_text_field_like => 'Nay!' })
        @data.length.should == 3 # Should return all but the first

        @paging[:total].should == 3

        @data[0].should == @entry1
        @data[0].content_score_a.should == 2
        @data[1].content_score_a.should == 1
      end

      it "shouldn't let user filters through if filter not exposed" do
        
        @publication.content_publication_fields.create(:field_type => 'value',:content_model_field_id => @cm.field(:string_field).id, :data => { :filter => 'filter'  })
        
        @publication.content_publication_fields.create(:field_type => 'value',:content_model_field_id => @cm.field(:text_field).id, :data => { :filter => 'filter'  })

        
        @paging, @data = @publication.get_list_data(1,{:filter_string_field_like => 'No', :filter_text_field_like => 'Nay!' }, {:filter_string_field_like => 'Yes', :filter_text_field_like => 'Yay!'} )
        @data.length.should == 1 # Should only return first


        @data[0].should == @entry1
      end

      it "should let user filters through if exposed" do
        @publication.content_publication_fields.create(:field_type => 'value',:content_model_field_id => @cm.field(:string_field).id, :data => { :filter => 'filter', :filter_options => ['expose']  })
        
        @publication.content_publication_fields.create(:field_type => 'value',:content_model_field_id => @cm.field(:text_field).id, :data => { :filter => 'filter', :filter_options => ['expose']  })

        
        @paging, @data = @publication.get_list_data(1,{:filter_string_field_like => 'No',:order => 'id' }, {:filter_string_field_like => 'Yes'} )
        
        @data.length.should == 2 # Should only return first

        @data[0].should == @entry0
        @data[1].should == @entry3
      end

    end
    
  end


  it "should filter items by content tags correctly" do
    @cm.update_attributes(:show_tags => true)

    @cm.reload
    cls = @cm.model_class(true)

    @entry0 = cls.create(:string_field => 'a', :text_field => 'Yay!', :tag_names => 'Yes, No, Maybe')
    @entry1 = cls.create(:string_field => 'b', :text_field => 'Nay!', :tag_names => 'Yes, Go Go, TaDa')
    @entry2 = cls.create(:string_field => 'c', :text_field => 'Yay!', :tag_names => 'Go Go')
    @entry3 = cls.create(:string_field => 'd', :text_field => 'Nay!', :tag_names => 'No, Maybe, TaDa')

    @publication = @cm.content_publications.create(:name => 'List',:publication_type => 'list',:publication_module => 'content/core_publication')


   @tag = ContentTag.find_by_name('Go Go')

   @paging, @data = @publication.get_list_data(1, { :tags => [ @tag.id ]  }  )
   @data.length.should == 2 # Should only return first

   @data.include?(@entry0).should be_false
   @data.include?(@entry1).should be_true
   @data.include?(@entry2).should be_true

  end

end
