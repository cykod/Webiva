# Copyright (C) 2009 Pascal Rettig.


module ModelExtension::OptionsExtension


  module ClassMethods 
    def has_options(field,options_select)
    
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
      
    end 
  end
  
  def self.append_features(mod)
    super
    mod.extend ModelExtension::OptionsExtension::ClassMethods
  end
    


end
