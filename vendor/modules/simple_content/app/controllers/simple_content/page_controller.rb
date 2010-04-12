class SimpleContent::PageController < ParagraphController

  editor_header 'Simple Content Paragraphs'
  
  editor_for :structured_view, :name => "Structured view", :feature => :simple_content_page_structured_view

  def structured_view
    @options = self.class.paragraph_options(:structured_view, paragraph.data)

    @paragraph_index = params[:path][4]

    @simple_content_model = SimpleContentModel.new(params[:simple_content_model]) if myself.has_role?('simple_content_manager')

    skip = (params[:skip] || 0).to_i
    if @options.simple_content_model.nil?
      @options.validate_data_model = false
      @options.attributes = params[:structured_view] if params[:structured_view]

      if request.post?
        if @simple_content_model && params[:simple_content_model]
          if @simple_content_model.save
            @options.simple_content_model_id = @simple_content_model.id
          end
        end

        if @options.valid?
          @paragraph.data = @options.to_h
          @paragraph.site_feature_id = params[:site_feature_id]
          @paragraph.save
          skip = 1
        end
      end
    else
      @options.assign_entry(params[:simple_content_data]) if params[:simple_content_data] && @options.simple_content_model
    end

    return if skip == 0 && handle_paragraph_update(@options)

    if @options.options_partial
      render :template => '/edit/edit_paragraph', :locals => {:paragraph_title => "#{args[:name]} Options",
        :paragraph_action => "structured_view" }
    end 
  end

  class StructuredViewOptions < HashModel
    attr_accessor :validate_data_model

    attributes :simple_content_model_id => nil, :data => {}

    validates_presence_of :simple_content_model_id
    integer_options :simple_content_model_id

    def self.simple_content_model_options
      SimpleContentModel.select_options_with_nil
    end

    def initialize(hsh)
      super
      @validate_data_model = true
    end

    def validate
      if @validate_data_model && self.simple_content_model
        errors.add(:data, 'is invalid') unless self.data_model.valid?
      end
    end

    def simple_content_model
      @simple_content ||= SimpleContentModel.find_by_id(self.simple_content_model_id)
    end

    def data_model
      return @data_model if @data_model
      return nil unless self.simple_content_model

      self.data ||= {}
      @data_model = self.content_model.create_data_model(self.data)
    end

    def content_model
      self.simple_content_model.content_model
    end

    def assign_entry(values = {},application_state = {})
      self.content_model.assign_entry(self.data_model, values, application_state)
      self.data = self.data_model.to_h
      self.data_model
    end
  end

end
