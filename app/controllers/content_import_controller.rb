# Copyright (C) 2009 Pascal Rettig.

require 'csv'

class ContentImportController < WizardController # :nodoc: all
  permit 'editor_content'
  
  @@deliminators = { 'semicolon' => ';', 'comma' => ',', 'colon' => ':', 'tab' => "\t" }

  
  wizard_steps [ [ 'index', 'Select File' ],
                 [ 'fields', 'Match Fields' ],
                 [ 'confirm', 'Confirm' ],
                 [ 'import', 'Import' ] ]
  
  def index
    content_id = params[:path][0]
    cms_page_info([ [ 'Content', url_for(:controller => 'content', :action => 'index') ] , 
                    [ 'View Content', url_for(:controller => 'content',:action => 'view', :path => content_id) ],
                    'Import Data' ])
  
    @content_model = ContentModel.find(content_id)
  
    if params[:previous]
      @wizard = DefaultsHashObject.new((session[:content_import_wizard] || {})[:index])
    else
      session[:content_import_wizard] = {}
      session[:content_import_worker_key] = nil
      @wizard = DefaultsHashObject.new(params[:wizard])
    end
    
    if(@wizard.csv_file) 
      @enable_next = true
    end
    
    if request.post?
      
      file = DomainFile.find_by_id(@wizard.csv_file)

      if(file)
        @wizard['filename'] = file.filename
  
        if(@wizard.filename =~ /\.xls$/i) 
          @wizard['filename'] = file.generate_csv
          @wizard['field_deliminator'] = @deliminator = "comma"
        else
          @deliminator = @wizard.field_deliminator
        end
      end
  
      if file && valid_csv(@wizard.filename,@@deliminators[@deliminator])
        session[:content_import_wizard][:index]  = @wizard.to_h
        redirect_to :action => 'fields', :path => content_id
      else 
        @bad_file = true
      end
      
      
    end
    
  end
  
  def fields
    content_id = params[:path][0]
    cms_page_info([ [ 'Content', url_for(:controller => 'content', :action => 'index') ] , 
                    [ 'View Content', url_for(:controller => 'content',:action => 'view', :path => content_id) ],
                    'Import Data' ])
  
    @content_model = ContentModel.find(content_id)
  
    if !session[:content_import_wizard] || !session[:content_import_wizard][:index]
      redirect_to :action => 'index'; return
      return
    end

    file = DomainFile.find_by_id(session[:content_import_wizard][:index][:csv_file])
    filename = file.filename

    @deliminator = @@deliminators[session[:content_import_wizard][:index][:field_deliminator]]

    @available_fields = csv_fields(filename,@deliminator)
    session[:content_import_wizard][:fields] ||= {}
    
    submitted_actions = params[:act] || session[:content_import_wizard][:fields][:actions]
    submitted_matches = params[:match] || session[:content_import_wizard][:fields][:matches] || {}
    submitted_created_fields = params[:create] || session[:content_import_wizard][:fields][:create] || {}  
    if params[:match]
      submitted_identifiers = params[:ident] || {}
    else
      submitted_identifiers =  session[:content_import_wizard][:fields][:identifiers] || {}
    end
    
    if request.post?
      @invalid_match = false
      submitted_actions.each do |idx,act|
        if act == 'm' && submitted_matches[idx].blank?
          @invalid_match = true
        end
      end
      unless @invalid_match
	    session[:content_import_wizard][:fields][:actions] = submitted_actions
	    session[:content_import_wizard][:fields][:matches] = submitted_matches
	    session[:content_import_wizard][:fields][:create] = submitted_created_fields
	    session[:content_import_wizard][:fields][:identifiers] = submitted_identifiers 
	    redirect_to :action => 'confirm', :path => @content_model.id
	    return
      end
    end
    
    @content_fields = [ContentModelField.new(:field => 'id', :name => 'Identifier'.t)] + @content_model.content_model_fields

    @content_options = @content_fields.collect { |fld| [ fld.name, fld.field ] }
    @field_types = ContentModel.content_field_options

    
    @matched_fields = []
    @available_fields.each_with_index do |fld,idx|
      match = nil
      if submitted_actions
        match = { :action => submitted_actions[idx.to_s], :field => submitted_matches[idx.to_s].to_s }
      else 
        match = @content_fields.detect do |clb|
          [ clb.name.downcase, clb.field.downcase ].include?(fld.downcase)
        end
        match[:action] = 'm' if match
      end
      @matched_fields << [ fld, match ?  match[:action] : 'i', match ? match[:field] : '' ]
    end 
    
    @back_button_url = url_for :action => 'index', :path => @content_model.id
    @enable_next = true
    
  end
  
  def confirm
    content_id = params[:path][0]
    cms_page_info([ [ 'Content', url_for(:controller => 'content', :action => 'index') ] , 
                    [ 'View Content', url_for(:controller => 'content',:action => 'view', :path => content_id) ],
                    'Import Data' ])
  
    @content_model = ContentModel.find(content_id)
 
    file = DomainFile.find_by_id(session[:content_import_wizard][:index][:csv_file])
    filename = file.filename

    @deliminator = @@deliminators[session[:content_import_wizard][:index][:field_deliminator]]
    
    @content_fields = [ContentModelField.new(:field => 'id', :name => 'Identifier'.t)] + @content_model.content_model_fields
        
    @content_options = @content_fields.collect { |fld| [ fld.name, fld.field ] }
    @field_types = ContentModel.content_field_options
    
    
    @page = params[:page] || 1
    
    if request.post?
      # Posting? Do it Do it
      
      worker_args = {
        :domain_id => DomainModel.active_domain_id,
        :csv_file => session[:content_import_wizard][:index][:csv_file],
        :content_model_id => content_id, 
        :deliminator => @deliminator,
        :data => session[:content_import_wizard][:fields]
      }

      session[:content_import_worker_key] =  ContentImportWorker.async_do_work(worker_args)
      # Start a worker that will create any necessary fields
      # and actually import the data
      
      redirect_to :action => 'import', :path => @content_model.id
      return
    else 
      # if we aren't posting, just grab a small window of data, and don't do the import itself
      @file_fields, @file_data= @content_model.import_csv(
                                    filename,
                                    session[:content_import_wizard][:fields],
                                    :page => @page,
                                    :deliminator => @deliminator,
                                    :import => false)
                                    
    end
  
    @back_button_url = url_for :action => 'fields', :path => @content_model.id
    @next_button = "Import"
    @enable_next = true
  end
  
  def import
    content_id = params[:path][0]
    cms_page_info([ [ 'Content', url_for(:controller => 'content', :action => 'index') ] , 
                    [ 'View Content', url_for(:controller => 'content',:action => 'view', :path => content_id) ],
                    'Import Data' ])
  
    @content_model = ContentModel.find(content_id)
  
    status
  
    @back_button_url = url_for :action => 'confirm', :path => @content_model.id
  
    @finished_onclick = "document.location='#{url_for(:controller => 'content',:action => 'view', :path => content_id)}';"
    @hide_back = false
    @enable_next = false
    
  end
  
  def status
    if session[:content_import_worker_key]
      begin 
        results = Workling.return.get(session[:content_import_worker_key]) || { }
        @initialized = results[:initialized] || false
        @completed = results[:completed] || false
        @entries = results[:entries] || 0
        @imported = results[:imported] || 0
	
        if @initialized && @entries > 0
          @percentage = (@imported.to_f / (@entries.to_i < 1 ? 1 : @entries) *100).to_i
          if @entries < 1
            @entries = 1
          end

        else
          @entries = nil
          @percentage = 0
        end
	
	if @completed
          session[:content_import_worker_key] = nil
        end
      rescue Exception => e
        raise e
        @invalid_worker = true
      end
    else
      @invalid_worker = true 
    end
  end
  
  
  
  private
  
 def valid_csv(filename,deliminator = ',')
      begin
        reader = CSV.open(filename,"r",deliminator) 
      rescue Exception => err
        raise err.to_s
        return false
      end
      reader.close
      return true
  end
  
  def csv_fields(filename,deliminator = ',')
    begin 
      reader = CSV.open(filename,"r",deliminator)
      fields = reader.shift.collect do |fld|
        fld.to_s.strip
      end 
    rescue Exception => e
      return false
    end
    reader.close
    
    return fields
  end
  
  
end
