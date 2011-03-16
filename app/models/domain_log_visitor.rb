require 'resolv'

class DomainLogVisitor < DomainModel
   belongs_to :end_user
 
   before_create :generate_hash

   has_many :domain_log_sessions, :order => 'domain_log_sessions.created_at DESC'
   has_many :experiment_users

   def last_session
     self.domain_log_sessions[0]
   end


   def ip_address_name
     Resolv.new.getname(self.ip_address)
   rescue Exception => e
     "No DNS Lookup"
   end

   def generate_hash
      self.visitor_hash = DomainModel.generate_hash 
   end

   def session_details(session_limit = 10)
     self.domain_log_sessions.find(:all,:include => :domain_log_entries,:limit => 10)
   end

   def has_location?
     self.country && self.country != 'UN'
   end

   def location_display
     [ city, region, country ].reject(&:blank?).join(", ")
   end


   def self.log_visitor(cookies,user,session,request)
      
      if cookies[:v] && !session[:domain_log_visitor]
        dlv = DomainLogVisitor.find_by_visitor_hash(cookies[:v])
        if dlv 
          if user.id && dlv.end_user_id != user.id
            if dlv.end_user_id.blank?
              dlv.end_user_id = user.id
            else
              cookies[:v] = nil
            end
          end

          if cookies[:v]
            dlv.update_attributes(:updated_at => Time.now)
            session[:domain_log_visitor] = { :id => dlv.id, :loc => dlv.country, :end_user_id => user.id  }
          end
        else
          cookies[:v] = nil
        end
      elsif cookies[:v] && session[:domain_log_visitor].is_a?(Integer)
        div = DomainLogVisitor.find_by_id session[:domain_log_visitor]
        session[:domain_log_visitor] = { :id => dlv.id, :loc => dlv.country, :end_user_id => user.id } if div
      end

      if  !cookies[:v]
        dlv = DomainLogVisitor.create(:ip_address => request.remote_ip, :end_user_id => user.id)
        cookies[:v] = {:value => dlv.visitor_hash, :expires => 20.years.from_now.utc }
        session[:domain_log_visitor] = { :id => dlv.id, :loc => dlv.country, :end_user_id => user.id }
      end

      DomainLogVisitor.log_user(cookies,session,user)

      # Need to capture the country and the location
      session[:domain_log_visitor][:loc] ? false : true
   end

   def self.log_user(cookies,session,user)
     if cookies[:v] && user.id && session[:domain_log_visitor][:id] && session[:domain_log_visitor][:end_user_id].blank?
       dlv =  DomainLogVisitor.find_by_visitor_hash(cookies[:v])
       dlv.update_attribute(:end_user_id,user.id) if dlv
     end
   end

   def self.log_location(cookies,session,location = {})
     if cookies[:v] && session[:domain_log_visitor] && session[:domain_log_visitor][:id] && session[:domain_log_visitor][:loc].blank?
       dlv =  DomainLogVisitor.find_by_visitor_hash(cookies[:v])
       if dlv
         location ||= {}
         location[:country] = 'UN' if location[:country].blank?
         dlv.update_attributes(location.slice(:latitude,:longitude,:country,:region,:city))
         session[:domain_log_visitor][:loc] = location[:country]
       end
     end
   end
end
