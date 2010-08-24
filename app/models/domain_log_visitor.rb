

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
          session[:domain_log_visitor] =  dlv.id
        else
          cookies[:v] = nil
        end
      end

      if  !cookies[:v]
        dlv = DomainLogVisitor.create(:ip_address => request.remote_ip, :end_user_id => user.id)
        cookies[:v] = {:value => dlv.visitor_hash, :expires => 20.years.from_now.utc }
        session[:domain_log_visitor] = dlv.id
      end

   end
end
