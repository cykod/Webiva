require 'time'

class Date
  class << self
    alias :org_parse :_parse

    # switch the month and day field for expecting US dates
    def _parse(str, comp=true)
      str = str.sub(/(\d{1,2})\/(\d{1,2})\/(\d{1,4})/, '\2/\1/\3')
      org_parse str, comp
    end
  end
end
