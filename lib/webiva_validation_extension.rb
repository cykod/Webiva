# Copyright (C) 2009 Pascal Rettig.


module WebivaValidationExtension


  module ClassMethods
    def validates_date(*attr_names)
      configuration =
        { :message => 'is an invalid date ',
          :on => :save
        }
      configuration.update(attr_names.pop) if attr_names.last.is_a?(Hash)
      # Don't let validates_each handle allow_nils, it checks the cast value.
      allow_nil = configuration.delete(:allow_nil)
      from = Time.parse_date(configuration.delete(:from))
      to = Time.parse_date(configuration.delete(:to))
      validates_each(attr_names, configuration) do |record, attr_name, value|
        before_cast = record.respond_to?("#{attr_name}_before_type_cast") ? record.send("#{attr_name}_before_type_cast") : record.send(attr_name)
        next if allow_nil and (before_cast.nil? or before_cast == '')
        next if before_cast.is_a?(Time)
        next if before_cast.is_a?(Date)
        next if before_cast.is_a?(String) &&  ( before_cast =~  /^([0-9]{4}\-[0-9]{2}\-[0-9]{2})$/ ||  before_cast =~  /^([0-9]{4}\-[0-9]{2}\-[0-9]{2} [0-9]{1,2}\:[0-9]{2}\:[0-9]{2})$/ )
        begin
          date = Time.parse_date(before_cast)
          record.send("#{attr_name}=",date)
        rescue Exception => e
          record.errors.add(attr_name, configuration[:message])
        else
          if from and date < from
            record.errors.add(attr_name,
                              "cannot be less than #{from.strftime('%e-%b-%Y')}")
          end
          if to and date > to
            record.errors.add(attr_name,
                              "cannot be greater than #{to.strftime('%e-%b-%Y')}")
          end
        end
      end
    end
    
    def validates_datetime(*attr_names)
      configuration =
        { :message => 'is an invalid date and time',
          :on => :save
        }
      configuration.update(attr_names.pop) if attr_names.last.is_a?(Hash)
      # Don't let validates_each handle allow_nils, it checks the cast value.
      allow_nil = configuration.delete(:allow_nil)
      from = Time.parse_datetime(configuration.delete(:from))
      to = Time.parse_datetime(configuration.delete(:to))
      validates_each(attr_names, configuration) do |record, attr_name, value|
        before_cast = record.send("#{attr_name}_before_type_cast")
        next if allow_nil and (before_cast.nil? or before_cast == '')
        next if before_cast.is_a?(Time)
        next if before_cast.is_a?(String) &&  before_cast =~  /^([0-9]{4}\-[0-9]{2}\-[0-9]{2} [0-9]{1,2}\:[0-9]{2}\:[0-9]{2})$/
        begin
          date = Time.parse_datetime(before_cast)
          record.send("#{attr_name}=",date)
        rescue
          begin
            date = Time.parse_date(before_cast)
            record.send("#{attr_name}=",date)
          rescue
            record.errors.add(attr_name, configuration[:message])
          end
        else
          if from and date < from
            record.errors.add(attr_name,
                              "cannot be earlier than #{from.strftime('%e-%b-%Y')}")
          end
          if to and date > to
            record.errors.add(attr_name,
                              "cannot be later than #{to.strftime('%e-%b-%Y')}")
          end
        end
      end
    end
  end
  
  def self.append_features(base) #:nodoc:
    super
    base.extend(ClassMethods)
  end
end
