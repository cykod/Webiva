def activate_domain!(domain)
  DomainModel.activate_domain domain
end
  
def reload_domain!
  domain = DomainModel.active_domain
  reload!
  unless domain.blank?
    puts "Activating #{domain[:name]}..."
    activate_domain! domain
  end
  true
end

