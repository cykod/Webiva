

class DomainLogVisitor < DomainModel
   belongs_to :end_user
 
   before_create :generate_hash


   def generate_hash
      self.visitor_hash = DomainModel.generate_hash 
   end



   def self.log_visitor(cookies,user,session,request)
      
      if cookies[:v] && !session[:domain_log_visitor]
        dlv = DomainLogVisitor.find_by_visitor_hash(cookies[:v][:value])
        if dlv 
          if user.id && dlv.end_user_id != user.id
            if dlv.end_user_id.blank?
              dlv.update_attribute(:end_user_id,user.id)
            else
              cookies[:v] = nil
            end
          end
          session[:domain_log_visitor] = { :id => dlv.id, :loc => dlv.country }
        else
          cookies[:v] = nil
        end
      end

      if  !cookies[:v]
        dlv = DomainLogVisitor.create(:ip_address => request.remote_ip, :end_user_id => user.id)
        cookies[:v] = {:value => dlv.visitor_hash, :expires => 20.years.from_now.utc }
        session[:domain_log_visitor] = { :id => dlv.id, :loc => dlv.country }
      end

      # Need to capture the country and the location
      session[:domain_log_visitor][:loc] ? false : true
   end

   def self.log_location(cookies,session,location = {})
     if cookies[:v] && session[:domain_log_visitor][:id] && session[:domain_log_visitor][:loc].blank?
       session[:domain_log_visitor] ||= {}
       dlv =  DomainLogVisitor.find_by_visitor_hash(cookies[:v])
       if dlv
         location[:country] = 'UN' if location[:country].blank?
         dlv.update_attributes(location.slice(:latitude,:longitude,:country,:region,:city))
         session[:domain_log_visitor][:loc] = location[:country]
       end
     end
   end
end
