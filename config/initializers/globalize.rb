
module Globalize
  class ModelTranslation
    def self.connection
      DomainModel.connection
    end
  end
end

Globalize::ModelTranslation.set_table_name('globalize_translations')


# Globalize Setup
include Globalize
# Base Language is always en-US - Language application was written in
Locale.set_base_language('en-US')
