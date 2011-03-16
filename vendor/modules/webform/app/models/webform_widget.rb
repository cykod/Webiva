
class WebformWidget < Dashboard::WidgetBase
  widget :results, :name => 'Results: Display Webform Results', :title => 'Webform Results', :permission => :webform_manage

  def results
    set_title_link url_for(:controller => '/webform/manage')

    conditions = options.new_results ? {:reviewed => false} : {}
    @results = WebformFormResult.find(:all, :conditions => conditions, :order => :posted_at, :limit => options.limit)

    render_widget :partial => '/webform/widget/results', :locals => { :results => @results, :options => options }
  end

  class ResultsOptions < HashModel
    attributes :new_results => true, :limit => 10

    boolean_options :new_results
    integer_options :limit
    validates_numericality_of :limit

    options_form(
                 fld(:limit, :text_field, :label => 'Number of results to diaply'),
                 fld(:new_results, :radio_buttons, :options => [['Yes'.t,true],['No'.t,false]], :label => 'Only display new results')
                 )
  end

end
