class Feed::PageController < ParagraphController

  editor_header 'Feed Paragraphs'
  
  editor_for :show, :name => "Generic Feed", :feature => :feed_page_show

  class ShowOptions < HashModel
    attributes :url => nil, :cache_time => nil, :format => 'xml', :timeout => 3

    integer_options :cache_time, :timeout

    validates_presence_of :url

    validating_options :format, [['Xml','xml'],['JSON','json']]

    options_form(
                 fld(:url,:text_field,:size => 80),
                 fld(:cache_time,:select,:options => :time_options),
                 fld(:format,:radio_buttons,:options => :format_select_options ),
                 fld(:timeout,:select, :options => :timeout_options)
                 )

  def timeout_options
     (1..6).to_a.map {  |opt| ["%d seconds" / opt, opt]}
  end
    def time_options
      (1..20).to_a.map {  |opt| ["%d Minutes" / opt, opt]}
    end

  end

end
