# Copyright (C) 2009 Pascal Rettig.

require 'csv'

class MemberImportController < WizardController # :nodoc: all
  permit 'editor_members'
  
  @@deliminators = { 'semicolon' => ';', 'comma' => ',', 'colon' => ':', 'tab' => "\t" }
  
  wizard_steps [ [ 'index', 'Select File' ],
                 [ 'fields', 'Match Fields' ],
                 [ 'options', 'Options' ],
                 [ 'confirm', 'Confirm' ],
                 [ 'import', 'Import' ] ]
  
  cms_admin_paths 'people', "People" => { :controller => 'members' }

  def index
    cms_page_path [ "People" ], "Member Import"
  
    if params[:previous]
      @wizard = DefaultsHashObject.new((session[:member_import_wizard] || {})[:index])
    else
      session[:member_import_wizard] = {}
      session[:member_import_worker_key] = nil
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
        session[:member_import_wizard][:index]  = @wizard.to_h
        redirect_to :action => 'fields'
      else 
        @bad_file = true
      end
      
      
    elsif params[:bad]
      @bad_file = true
    end
    
    
  end
  
  def fields
   cms_page_path [ "People" ], "Member Import - Match Fields"

    if !session[:member_import_wizard] || !session[:member_import_wizard][:index]
      redirect_to :action => 'index'; return
      return
    end

    @deliminator = @@deliminators[session[:member_import_wizard][:index][:field_deliminator]]

    file = DomainFile.find_by_id(session[:member_import_wizard][:index][:csv_file])
    filename = file.filename
    
    begin 
      @available_fields = csv_fields(filename,@deliminator)
      
      if !@available_fields
        redirect_to :action => :index, :bad => true
        return
      end
    #rescue Exception => e
    #  redirect_to :action => :index, :bad => true
    #  return
    end
    
    session[:member_import_wizard][:fields] ||= {}
    
    submitted_actions = params[:act] || session[:member_import_wizard][:fields][:actions]
    submitted_matches = params[:match] || session[:member_import_wizard][:fields][:matches] || {}
    submitted_created_fields = params[:create] || session[:member_import_wizard][:fields][:create] || {}  
    
    
    if request.post?
      # Verify that we are matching the email
      email_index = nil
      submitted_matches.each do |idx,value|
        if value == 'email' && submitted_actions[idx] == 'm'
          email_index = idx.to_i
	end
      end
      
      if email_index
	session[:member_import_wizard][:fields][:actions] = submitted_actions
	session[:member_import_wizard][:fields][:matches] = submitted_matches
	session[:member_import_wizard][:fields][:create] = submitted_created_fields
	redirect_to :action => 'options'
	return
      else
        @missing_email = true
      end
    end
    
    @member_fields = EndUser.import_fields
    if SiteModule.module_enabled?('user_profile')
      @member_fields += UserProfileType.import_fields
    end
        
    @member_field_options = @member_fields.collect { |fld| [ fld[1], fld[0] ] }
    
    @matched_fields = []
    @available_fields.each_with_index do |fld,idx|
      match = nil
      if submitted_actions
        match = { :action => submitted_actions[idx.to_s], :field => submitted_matches[idx.to_s].to_s }
      else 
        match_field = @member_fields.detect do |clb|
          clb[2].include?(fld.downcase) || fld.downcase == clb[0] || fld.downcase == clb[1].downcase
        end
        match = { :action => 'm' }
        if match_field 
          match[:field] = match_field[0]
        end
      end
      @matched_fields << [ fld, match ?  match[:action] : 'i', match ? match[:field] : nil ]
    end 
    
    @enable_next = true
    
  end
  
  def options
    cms_page_path [ "People" ], "Member Import - Options"
     
    if request.post?
      session[:member_import_wizard][:options] = params[:options]
      redirect_to :action => 'confirm'
    end
     
    @options = DefaultsHashObject.new(params[:options] || session[:member_import_wizard][:options] ||  { :import_mode => 'normal' } )
 
    @segments = UserSegment.select_options_with_nil 'User List', :conditions => {:segment_type => 'custom'}, :order => 'name'
    @segments += [['--Create a new User List--', 'create']]

    @enable_next = true
  end
  
  def confirm
    cms_page_path [ "People" ], "Member Import - Confirm "
    
    file = DomainFile.find_by_id(session[:member_import_wizard][:index][:csv_file])
    filename = file.filename

    @deliminator = @@deliminators[session[:member_import_wizard][:index][:field_deliminator]]
    
    @page = params[:page] || 1
    
    if request.post?
      # Posting? Do it Do it
      
      worker_args = {
        :domain_id => DomainModel.active_domain_id,
        :csv_file => session[:member_import_wizard][:index][:csv_file],
        :data => session[:member_import_wizard][:fields],
        :options => session[:member_import_wizard][:options],
        :deliminator => @deliminator
      }
      worker_key = MemberImportWorker.async_do_work(worker_args)
      session[:member_import_worker_key] = worker_key
      # Start a worker that will create any necessary fields
      # and actually import the data
      
      redirect_to :action => 'import'
      return
    else 
      # if we aren't posting, just grab a small window of data, and don't do the import itself
      @file_fields, @file_data= EndUser.import_csv(
                                    filename,
                                    session[:member_import_wizard][:fields],
                                    :page => @page,
                                    :options => session[:member_import_wizard][:options],
                                    :deliminator => @deliminator,
                                    :import => false)
                                    
    end
  
    @next_button = "Import"
    @enable_next = true
  end
  
  def import
    cms_page_path [ "People" ], "Member Import - Import Data"

    status
  
    @back_button_url = url_for :action => 'confirm'
  
    @finished_onclick = "document.location='#{url_for(:controller => 'members')}';"
    @hide_back = false
    @enable_next = false
    
  end

  def status
    if session[:member_import_worker_key]
      results = Workling.return.get(session[:member_import_worker_key]) || { }
      @initialized = results[:initialized]
      @completed = results[:completed]
      @errors = results[:errors]
      @entries = results[:entries].to_i
      @imported = results[:imported].to_i
      @entries = 1 if @entries == 0
      @percentage = (@imported.to_f / @entries.to_f * 100.0).to_i
    else
      @invalid_worker = true 
    end
  end

  
  
  private

  def open_csv(filename,deliminator = ',')
    reader = nil
    header = []
    begin 
      begin 
        reader = CSV.open(filename,"r",deliminator)
        header = reader.shift
      rescue Exception => e
        reader = CSV.open(filename,"r",deliminator,?\r)
        header = reader.shift
      end
    rescue Exception => e
      return nil
    end
    return [ reader,header ]
  end
  
  def valid_csv(filename,deliminator = ',')
    reader,header = open_csv(filename,deliminator)
    return reader
  end
  
  def csv_fields(filename,deliminator = ',')
    reader,header = open_csv(filename,deliminator)
    if reader
      fields = header.map(&:to_s).map(&:strip)
      reader.close
      return fields
    end
  end
end
