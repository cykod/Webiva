# Copyright (C) 2009 Pascal Rettig.

class SelectorController < CmsController #:nodoc:all
  layout 'manage_window'

  def popup
  
    @class_name = params[:class_name]
    cls = @class_name.classify.constantize
    
    @name = params[:name]
    @field = params[:field]
    @callback = params[:callback]
    
    if @class_name == 'end_user'
      @order = 'last_name, first_name'
    else
      @order = 'name'
    end
    
    @objects = cls.find_select_options(:all,:order => @order)
    
    
    
  end
  
  def popup_multi
    
    @class_name = params[:class_name]
    cls = @class_name.classify.constantize
    
    @name = params[:name]
    @field = params[:field]
    @field_name = params[:field_name]
    @callback = params[:callback]
    
    if @class_name == 'end_user'
      @order = 'last_name, first_name'
    else
      @order = 'name'
    end
    
    @objects = cls.find_select_options(:all,:order => @order)
    
    @selected = DefaultsHashObject.new(:content_ids => params[:content_ids].split(",").map { |elm| elm.to_i })
      
  end


end

