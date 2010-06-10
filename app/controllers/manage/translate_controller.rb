# Copyright (C) 2009 Pascal Rettig.



class Manage::TranslateController < CmsController # :nodoc: all
  skip_before_filter :context_translate_before
  skip_after_filter :context_translate_after

  helper :translate

  permit 'system_admin'
  layout 'manage'

    # need to include 
   include ActiveTable::Controller   
   active_table :view_translation_table,
                Globalize::ViewTranslation,
                [ ActiveTable::IconHeader.new('',:width => 16),
                  ActiveTable::NumberHeader.new('id',:label => 'ID'),
                  ActiveTable::StringHeader.new('tr_key',:label => 'Text'),
                  ActiveTable::ExistsHeader.new('globalize_translations.text', :label => 'Exists?'),
                  ActiveTable::StringHeader.new('text', :label => 'Translation'),
                  ActiveTable::DateRangeHeader.new('updated_at', :label => 'Updated', :width => 100)

                ]

  def view_translation_table(display=true)

    @no_translation_text = '--No Translation--'


    if request.post?
      case params[:table_action].to_s
      when 'delete':  
        if params[:trans].is_a?(Hash)
          ViewTranslation.delete(params[:trans].keys);
        end
      else
        if params[:translation].is_a?(Hash)
          params[:translation].each do |trans_id,val|
            if val != @no_translation_text
              if(params[:translation_orig][trans_id] != val)
                ViewTranslation.find(trans_id).update_attribute(:text,val)
              end
            end
          end
        end
      end
    end 
      
    @active_table_output = view_translation_table_generate params, :conditions => [ 'language_id = ?', Locale.language.id ], :order => 'text is NULL desc, id DESC'

    render :partial => 'view_translation_table' if display
  end


  def index    
    cms_page_info('Translation','system');
    
    

    if(params[:language]) 
      session[:cms_language] = params[:language]
      redirect_to :action => 'index'
      return
    end
    @languages = Configuration.languages
    
    # 'built_in = 0 AND  - built in fix
    # @view_translations = ViewTranslation.find(:all, :conditions => [ 'language_id = ?', Locale.language.id ], :order => 'text is NULL desc, id DESC')
    view_translation_table(false)

  end

  def translation_text
    @translation = ViewTranslation.find(params[:id])
    render :text => @translation.text || ""  
  end

  def set_translation_text
    @translation = ViewTranslation.find(params[:id])
    previous = @translation.text
    @translation.text = params[:value]
    @translation.text = previous unless @translation.save
    
    Locale.clear_cache
    render :partial => "translation_text", :object => @translation.text  
  end
  
  def remove_entry
    @translation = ViewTranslation.find(params[:id])
    if @translation
      ViewTranslation.delete_all(["tr_key = ?",@translation.tr_key])
    end
    render :nothing => true
  end
  
  def context
  
    session[:requests] = []
    
    @requests = params[:requests] || session[:context_translation_requests].uniq
    @requests.sort!
    @requests.collect! do |req|
      trans = ViewTranslation.find(:first,:conditions => [ 'language_id = ? AND tr_key= ?', Locale.language.id ,req]) || ViewTranslation.new
      [ req, trans.id, trans.text ]
    end
    
    
    render :action=>'context', :layout => 'manage_window'
  end
  
  def context_save
     text = params[:text] || {}
     translations = params[:translate] || {}
     translations.each do |idx,translation|
        translation = nil if translation.empty?
        Locale.set_translation(text[idx],translation)
     end
    
    render :nothing => true
  end
end
