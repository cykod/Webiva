require 'pathname'
require 'singleton'

ml_lib_path = "#{Rails.root}/vendor/plugins/lib/globalize"

# Load globalize libs
require "globalize/localization/db_view_translator"
require "globalize/localization/rfc_3066"
require "globalize/localization/locale"
require "globalize/localization/db_translate"
require "globalize/localization/core_ext"
require "globalize/localization/core_ext_hooks"

# Load plugin models
require "globalize/models/translation"
require "globalize/models/model_translation"
require "globalize/models/view_translation"
require "globalize/models/language"
require "globalize/models/country"
require "globalize/models/currency"

# Load overriden Rails modules
#require "globalize/rails/active_record" - removed PFR
#require "globalize/rails/action_view" - removed PFR
require "globalize/rails/action_mailer"
require "globalize/rails/date_helper"
require "globalize/rails/active_record_helper"
