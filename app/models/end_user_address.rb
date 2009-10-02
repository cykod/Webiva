# Copyright (C) 2009 Pascal Rettig.

class EndUserAddress < DomainModel

  attr_protected :end_user_id
  belongs_to :end_user

  def validate_registration(type,required= false,display_type='us')
    case type
    when :work:
      fields = %w(company phone address city zip country)
      fields << 'state' if display_type == 'us'
    when :home,:billing:
      fields = %w(address city zip country)
      fields << 'state' if display_type == 'us'
    when :shipping
      fields = %w(first_name last_name address city zip country)
      fields << 'state' if display_type == 'us'
    end
    if required
      fields.each do |fld|
	fld = fld.to_sym
	errors.add(fld,'is missing') if self.send(fld).to_s.empty?
      end
    end
  end


  def display(connector = "\n",options={})
    output = []
    output << "#{CGI.escapeHTML(self.first_name)} #{CGI.escapeHTML(self.last_name)}" if first_name && last_name
    output << CGI.escapeHTML(company) unless company.blank?
    output << CGI.escapeHTML(address) unless address.blank?
    output << CGI.escapeHTML(address_2) unless address_2.blank?
    if options[:address_type] == 'european'
      output << CGI.escapeHTML("#{zip} #{city} #{state}" )
    else
      if !city.blank? && (!state.blank? || !zip.blank?)
        output << CGI.escapeHTML("#{city}, #{state} #{zip}")
      elsif city || state || zip
        output << CGI.escapeHTML("#{city} #{state} #{zip}")
      end
    end
    output << CGI.escapeHTML(country) if country && country != 'United States'
    
    output.join(connector)
  end

  def compare(adr)
    adr.first_name == first_name && 
    adr.last_name == last_name &&
    adr.address == address &&
    adr.address_2 == address_2 &&
    adr.city == city &&
    adr.state == state &&
    adr.zip == zip &&
    adr.phone == phone &&
    adr.company == company && 
    adr.fax == fax
  end
end
