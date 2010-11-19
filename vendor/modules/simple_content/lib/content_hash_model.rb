
class ContentHashModel
  attr_accessor :fields, :features

  def initialize(flds, features=nil)
    self.fields = flds
    self.features = features
  end

  def options; {}; end
  def form?; true; end

  def valid?
    valid_options = true
    self.content_model_fields.each do |field|
      invalid_options = false unless field.valid?
    end
    valid_options
  end

  def content_publication_fields
    return @content_publication_fields if @content_publication_fields

    @content_publication_fields = self.content_model_fields.collect do |field|
      ContentHashModelPublicationField.new field
    end
  end

  def content_model_fields
    return @content_model_fields if @content_model_fields
    return [] unless self.fields
    @content_model_fields = self.fields.collect do |field|
      ContentHashModelField.new self, field
    end
  end

  def content_model_fields=(fields)
    @content_model_fields = []
    return unless fields

    fields = fields.sort{ |a, b| a[1]['position'].to_i <=> b[1]['position'].to_i }.collect { |data| data[1] } if fields.is_a?(Hash)

    @content_model_fields = fields.collect do |data|
      ContentHashModelField.new self, field_data(data[:field]).merge(data.to_hash.symbolize_keys)
    end
  end

  def field_data(field)
    return {} unless self.fields
    return {} if field.blank?
    field = field.to_s
    self.fields.detect { |elm| elm[:field] == field } || {}
  end

  def content_model_features
    return @content_model_features if @content_model_features
    return [] unless self.features

    @content_model_features = self.features.collect do |feature|
      ContentHashModelFeature.new feature.to_hash.symbolize_keys
    end
  end

  def content_model_features=(features)
    @content_model_features = []
    return unless features

    @content_model_features = features.collect do |data|
      ContentHashModelFeature.new data.to_hash.symbolize_keys
    end

    self.features = @content_model_features.collect { |f| f.to_h }
    @content_model_features
  end

  def data_model_class
    return @cls if @cls
    @cls = Class.new(HashModel)
    @cls.send(:attr_accessor, :connected_end_user)
    # Setup the fields in the model as necessary (required, validation, etc)
    self.content_model_fields.each do |fld|
      fld.setup_model(@cls)
      @cls.attributes(fld.field.to_sym => nil);
    end
    @cls
  end

  def create_data_model(data)
    model = self.data_model_class.new(data)
    model.format_data
    model
  end

  # Given a set of parameters, modifies the attributes as necessary
  # for the fields
  def entry_attributes(parameters)
    parameters = parameters ? parameters.clone : { }
    self.content_model_fields.each do |fld|
      fld.modify_entry_parameters(parameters)
    end
    parameters
  end

  def assign_entry(entry,values = {},application_state = {})
    application_state = application_state.merge({:values => values })
    values = self.entry_attributes(values) 
    self.content_publication_fields.each do |fld|
      val = nil
      case fld.field_type
      when 'dynamic':
          val = fld.content_model_field.dynamic_value(fld.data[:dynamic],entry,application_state)
        fld.content_model_field.assign_value(entry,val)
      when 'input':
          fld.content_model_field.assign(entry,values)
      when 'preset':
          fld.content_model_field.assign_value(entry,fld.data[:preset])
      end
    end
    entry.valid?
    
    self.content_publication_fields.each do |fld|
      if fld.data && fld.data[:required]
        if fld.content_model_field.text_value(entry).blank?
          self.errors.add(fld.content_model_field.field,'is missing')
        end
      end
    end

    entry
  end

  def to_a
    fld_idx = 0
    self.content_model_fields.each do |field|
      fld_idx = fld_idx + 1
      field.field = generate_field_name(field, fld_idx) if field.field.blank?
      field.field_options['relation_name'] = field.field.sub(/_id$/, '') if field.content_field[:relation]
    end

    self.fields = self.content_model_fields.collect { |field| field.to_h }
  end

  def content_snippet(data_model, opts={})
    self.content_node_body(data_model, opts[:lang], opts.merge(:style => :excerpt))
  end

  def content_node_body(data_model, lang, opts={})
    separator = opts[:separator] || ' | '
    spacer = opts[:spacer] || ': '
    style = opts[:style] || :form

    self.content_model_fields.collect do |fld|
      if fld.is_type?('/content/core_field/header')
        nil
      else
        h(fld.name).to_s + spacer + fld.content_display(data_model,style).to_s
      end
    end.select { |fld| ! fld.nil? }.join(separator)
  end

  private
  def unique_field_name?(name)
    self.content_model_fields.detect { |field| field.field == name }.nil?
  end

  def generate_field_name(field, fld_idx)
    base_name = field.name.downcase.gsub(/[^a-z0-9]+/,"_")[0..20].singularize
    name = "#{base_name}#{field_post_fix(field)}"
    return name if unique_field_name?(name)
    "#{name}_#{fld_idx}#{field_post_fix(field)}"
  end

  def field_post_fix(field)
    return '_id' if field.content_field[:relation]
    return '_number' if field.content_field[:representation] == :integer
    ''
  end
end
