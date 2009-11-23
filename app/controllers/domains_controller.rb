# Copyright (C) 2009 Pascal Rettig.

class DomainsController < CmsController # :nodoc: all

  cms_admin_paths 'options',
  'Options' => { :controller => '/options' },
  'Domains' => { :controller => '/domains' }

  include ActiveTable::Controller

  active_table :domains_table, Domain,
  [ :check, 'Domain','Active','Options','WWW','Primary','Version' ]

  def index
    cms_page_path ['Options'],'Domains'
    display_domains_table(false)
  end

  def display_domains_table(display=true)

    active_table_action(:domain) do |act,dids|
      @domains = Domain.find(dids,:conditions => { :database =>  Configuration.domain_info.database })
      case act
      when 'activate':
          @domains.each { |dmn| dmn.update_attribute(:active,true) }
      when 'deactivate':
          @domains.each { |dmn| dmn.update_attribute(:active,false) }
      when 'delete':
          @domains.each { |dmn| dmn.destroy_domain }
      end
    end

    @tbl = domains_table_generate params,
    :conditions => ['client_id=? AND `database`=?',
                    Configuration.domain_info.client_id,
                    Configuration.domain_info.database
                   ],
    :order => 'name',
    :per_page => 100

    render :partial => 'domains_table' if display
  end

  def edit
    if params[:path][0]
      @dmn = Domain.find_site_domain(params[:path][0],Configuration.domain_info.database)
    else
      domain_info = Configuration.domain_info
      @dmn = Domain.new(Configuration.domain_info.attributes)
      @dmn.primary = false
      @dmn.name=''
      create_domain=true
    end

    cms_page_path ['Options','Domains'],@dmn.id ? ["Edit %s",nil,@dmn.name] : 'A a new domain to this site'

    if request.post? && params[:domain]
      if params[:commit]
        args = params[:domain].slice(:active, :name, :www_prefix, :restricted, :site_version_id, :inactive_message)
        if @dmn.update_attributes(args)
          if(create_domain)
            flash[:notice] = 'Added domain "%s" to site' / @dmn.name
          else
            flash[:notice] = 'Update domain "%s"' / @dmn.name
          end
          redirect_to :action => 'index'
          return
        end
      else
        redirect_to :action => 'index'
        return
      end
    end
  end

  def primary
    @dmn = Domain.find_site_domain(params[:path][0],Configuration.domain_info.database)

    if @dmn
      @dmn.set_primary
    end

    redirect_to :action => 'index'
  end

end
