class XmlValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    validator = Util::HtmlValidator.new value
    record.errors[attribute] << (options[:message] || "is not valid xml and has one or more errors:\n " + validator.errors.join(",\n ")) unless validator.valid?
  end
end
