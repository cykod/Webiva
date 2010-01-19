# Copyright (C) 2009 Pascal Rettig.


module ModelExtension::OptionsExtension


  module ClassMethods 

    # same as calling has_options(..,..,:validate => true)
    # add validates_inclusion_of to the field
    def validating_options(field,options_select,options={ })
      options[:validate] = true
      has_options(field,options_select,options)
    end

    # Allows you to specify the valid options for an attribute,
    # making it easier to keep those options in one place
    # 
    # Usage:
    #
    #       has_options(:example_field, [['Human Name 1','db_name1'],['Human Name 2','db_name2']])
    #
    # This will add a number of class methods, including:
    #
    # [self.example_field_options]
    #   Return a hash with db_name => original human name (not translated)
    # [self.example_field_options_hash]
    #   Same as above, except the human name is translated
    # [self.example_field_select_options]
    #   Will return a translated list of select-friendly options
    # [self.example_field_original_options]
    #   Will return a clone of original options_select passed in
    #
    # This will also add a instance method called example_field_display that will
    # return the translated human name of the attribute
    def has_options(field,options_select,opts={ })
    
      options_select = options_select.collect do |opt|
        if opt.is_a?(Array)
          [opt[0],opt[1]]
        else
          [opt.humanize,opt]
        end
      end
      
      options = Hash.new
      options_select.each do |opt|
        options[opt[1]] = opt[0]
      end
      
      class << self; self end.send(:define_method, "#{field.to_s}_options")  do
          options
      end

      class << self; self end.send(:define_method, "#{field.to_s}_options_hash")  do
          opt_hash = {}
          options_select.each do |opt|
            opt_hash[opt[1]] = opt[0].t
          end
         opt_hash
      end

      class << self; self end.send(:define_method,"#{field.to_s}_select_options") do
          options_select.collect do |opt|
            [opt[0].t,opt[1]]
          end
      end
      class << self; self end.send(:define_method,"#{field.to_s}_original_options") do
          options_select.clone
      end
      
      define_method "#{field.to_s}_display" do
        options[self.send(field)].t if options[self.send(field)]
      end
      

      if opts[:validate]
        validates_inclusion_of( field, 
                                :in =>  options_select.map { |elm| elm[1] },
                                :message => opts[:message] || "is invalid"
                                )
        
      end
    end 
  end
  
  def self.append_features(mod) #:nodoc:
    super
    mod.extend ModelExtension::OptionsExtension::ClassMethods
  end
    


end
