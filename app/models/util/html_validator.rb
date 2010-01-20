# Copyright (C) 2009 Pascal Rettig.

#require 'tidy'

require 'xml' 

# Utility class to validate html (with or without cms: tags)
#
# Example:
#
#     validator = Util::HtmlValidator.new(@str)
#     if validator.valid?
#       # Do something
#     else
#       error_string = validator.errors.join("<br/>")
#       # render errors ..
#    end
class Util::HtmlValidator


  def initialize(html)
    @html = html
  end

  # Call calidate if it hasn't been called yet and check if we have any errors
  def valid?
    self.validate if !@errors.is_a?(Array)
    @errors.length == 0
  end
  
  attr_reader :errors
  
  # Validates the html
  def validate
    @errors = []

# Tidy provided much better error messages, but also segfaulted constantly...    
#    Tidy.path = "/usr/lib/libtidy.so"
#    tidy = Tidy.new(:input_xml => true)
#    tidy.clean(@html)
#    @errors = tidy.errors
    parser = XML::Parser.string("<feature xmlns:cms='http://www.webiva.org/cms'>#{@html}</feature>")
    msgs = []
    XML::Error.set_handler { |msg| msgs << msg }
    begin
      parser.parse
    rescue Exception => e
      @errors = msgs.map { |e| e.to_s }
      @errors = @errors.select { |err| !(err =~ /Entity \'(.*)' not defined/) }
    end
    @errors = [] if !@errors ||  @errors.length == 0
    @errors
  end

end
