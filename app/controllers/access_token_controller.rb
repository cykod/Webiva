# Copyright (C) 2009 Pascal Rettig.
# Controller for manipulating AccessToken's
class AccessTokenController < CmsController # :nodoc:all

  permit 'editor_access_tokens'

  cms_admin_paths 'people',
  'People' => { :controller => '/members' },
  'User Access Tokens' => { :action => 'index' },
  'Editor Access Tokens' => { :action => 'editor' },
  'Options' => { :controller => '/options' },
  'Permissions' => { :controller => '/permissions' }

  include ActiveTable::Controller

  active_table :access_token_table, AccessToken,
   [ :check, 'token_name','User Count','description' ]
  
  def index

    cms_page_path ['People'],'User Access Tokens'

    display_access_token_table(false)
  end

  def display_access_token_table(display=true)

    active_table_action('token') do |act,aids|
      tokens = AccessToken.find(aids)
      case act
      when 'delete': tokens.map(&:destroy)
      end
    end

    @tbl = access_token_table_generate params, :order =>"token_name",:conditions => [ 'editor=0']
    
    render :partial => 'access_token_table' if display
  end

  def edit
    @token = AccessToken.find_by_id(params[:path][0]) || AccessToken.new(:editor => 0 )

    cms_page_path ['People','User Access Tokens'], @token.id ? ['Edit %s Token',nil,@token.token_name ] : 'Create a Token'

    if request.post? && params[:token]
      if params[:commit]
        if @token.update_attributes(params[:token].slice(:token_name,:description))
          redirect_to :action => 'index'
        end
      else
        redirect_to :action => 'index'
      end
    end
    
  end

  def editor
    cms_page_path ['Options','Permissions'], 'Editor Access Tokens', nil, 'options'

    display_editor_access_token_table(false)
  end

  def display_editor_access_token_table(display=true)

    active_table_action('token') do |act,aids|
      tokens = AccessToken.find(aids)
      case act
      when 'delete': tokens.map(&:destroy)
      end
    end    

    @tbl  = access_token_table_generate(params, :order =>'token_name',:conditions => [ 'editor=1'])

    render :partial => 'editor_access_token_table' if display
  end

  def edit_editor
    @token = AccessToken.find_by_id(params[:path][0]) || AccessToken.new(:editor => 1 )

    cms_page_path ['Options','Permissions', 'Editor Access Tokens'], @token.id ? ['Edit %s Token',nil,@token.token_name ] : 'Create a Token', nil, 'options'

    if request.post? && params[:token]
      if params[:commit]
        if @token.update_attributes(params[:token].slice(:token_name,:description))
          redirect_to :action => 'editor'
          return
        end
      else
        redirect_to :action => 'editor'
        return
      end
    end

    render :action => 'edit'
  end

end
