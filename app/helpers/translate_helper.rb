
module TranslateHelper # :nodoc:all

   
  def base_language_only
    yield if Locale.base?
  end

  def not_base_language
    yield unless Locale.base?
  end
end
