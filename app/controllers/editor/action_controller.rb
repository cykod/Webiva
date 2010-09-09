# Copyright (C) 2009 Pascal Rettig.

class Editor::ActionController < ParagraphController #:nodoc:all
  permit 'editor_editor'

  # Editor for authorization paragraphs
  editor_header "System Paragraphs", :paragraph_action
  editor_for :triggered_action, :name => 'Triggered Actions',  :triggers => [ ['View Page','view']]

  editor_for :html_headers, :name => 'HTML/JS/CSS Headers'

  editor_for :experiment, :name => 'Experiment Success'

  def triggered_action
  end

  class HtmlHeadersOptions < HashModel
    attributes :css => nil, :javascript => nil, :html_header => nil

    

    def validate
      css_files.each do |file|
        if(file =~ /^images\/(.*)$/)
          df = DomainFile.find_by_file_path("/#{$1}")
          if !df 
            self.errors.add(:css,'is an invalid file manager file:' + $1)
          end
        end
      end

      js_files.each do |file|
        if(file =~ /^images\/(.*)$/)
          df = DomainFile.find_by_file_path("/#{$1}")
          if !df
            self.errors.add(:javascript,'is an invalid file manager file:' + $1)
          end
        end
      end
    end
    
    def css_files
      @css_files ||= self.css.to_s.split("\n").select { |elm| !elm.blank? }.uniq
    end

    def js_files
      @js_files ||= self.javascript.to_s.split("\n").select { |elm| !elm.blank? }.uniq
    end
  end

  class ExperimentOptions < HashModel
    attributes :experiment_id => nil, :delayed => false, :delay_for => 10

    boolean_options :delayed
    integer_options :delay_for, :experiment_id

    validates_presence_of :experiment_id

    options_form(
                 fld(:experiment_id, :select, :options => :experiment_options),
                 fld(:delayed, :yes_no),
                 fld(:delay_for, :text_field, :size => 5, :unit => 'seconds')
                 )

    def self.experiment_options
      Experiment.find(:all, :conditions => ["ended_at >= ? || ended_at IS NULL", Time.now]).collect { |e| [e.name, e.id] }
    end
  end
end
