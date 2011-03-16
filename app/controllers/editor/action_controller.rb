# Copyright (C) 2009 Pascal Rettig.

class Editor::ActionController < ParagraphController #:nodoc:all

  # Editor for authorization paragraphs
  editor_header "System Paragraphs", :paragraph_action
  editor_for :triggered_action, :name => 'Triggered Actions',  :triggers => [ ['View Page','view']]

  editor_for :html_headers, :name => 'HTML/JS/CSS Headers'

  editor_for :experiment, :name => 'Experiment Conversion'

  editor_for :server_error, :name => 'Server Error', :no_options => true, :feature => :editor_action_server_error

  user_actions [:exp]

  def exp
    Experiment.success! params[:path][0], session
    render :nothing => true
  end

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
    attributes :experiment_id => nil, :type => 'automatic', :delay_for => 10

    integer_options :delay_for, :experiment_id

    validates_presence_of :experiment_id

    def manual_js
      self.experiment_id ? "WebivaExperiment.finished(#{self.experiment_id});" : ''
    end

    def onclick_js
      self.experiment_id ? "onclick=\"return WebivaExperiment.onclick(#{self.experiment_id}, this);\"" : ''
    end

    @@type_options = [['Automatic', 'automatic'], ['Delayed', 'delayed'], ['Manual', 'manual'], ['Onclick', 'onclick']]
    def self.type_options
      @@type_options
    end

    def experiment_options
      [['--Select Experiment--'.t, nil]] + Experiment.find(:all, :conditions => ["ended_at >= ? || ended_at IS NULL || id = ?", Time.now, self.experiment_id]).collect { |e| [e.name, e.id] }
    end

    def experiment
      @experiment ||= Experiment.find_by_id(self.experiment_id)
    end
  end
end
