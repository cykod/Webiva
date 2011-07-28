
class EndUserAddressSegmentField < UserSegment::FieldHandler

  def self.user_segment_fields_handler_info
    {
      :name => 'User Address Fields',
      :domain_model_class => EndUserAddress,
    }
  end

  register_field :home_address, EndUserAddressSegmentType::AddressStringType, :name => 'Home Address', :field => :address
  register_field :home_address_2, EndUserAddressSegmentType::AddressStringType, :name => 'Home Address (2)', :field => :address_2
  register_field :home_phone, EndUserAddressSegmentType::AddressStringType, :name => 'Home Phone', :field => :phone
  register_field :home_city, EndUserAddressSegmentType::AddressStringType, :name => 'Home City', :field => :city
  register_field :home_state, EndUserAddressSegmentType::AddressStringType, :name => 'Home State', :field => :state
  register_field :home_zip, EndUserAddressSegmentType::AddressStringType, :name => 'Home Zip', :field => :zip
  register_field :home_country, EndUserAddressSegmentType::AddressStringType, :name => 'Home Country', :field => :country

  register_field :work_address, EndUserAddressSegmentType::WorkAddressStringType, :name => 'Work Address', :field => :address
  register_field :work_address_2, EndUserAddressSegmentType::WorkAddressStringType, :name => 'Work Address (2)', :field => :address_2
  register_field :work_phone, EndUserAddressSegmentType::WorkAddressStringType, :name => 'Work Phone', :field => :phone
  register_field :work_city, EndUserAddressSegmentType::WorkAddressStringType, :name => 'Work City', :field => :city
  register_field :work_state, EndUserAddressSegmentType::WorkAddressStringType, :name => 'Work State', :field => :state
  register_field :work_zip, EndUserAddressSegmentType::WorkAddressStringType, :name => 'Work Zip', :field => :zip
  register_field :work_country, EndUserAddressSegmentType::WorkAddressStringType, :name => 'Work Country', :field => :country


 def self.get_handler_data(ids, fields)
   data = {}
   field_prefix = fields.map { |fld| fld.to_s.split("_")[0] }.compact.uniq
   field_mapping = { 'home' => 'address_id', 'work' => 'work_address_id' }

   field_prefix.each do |prefix|
      address_type = field_mapping[prefix]
      data[prefix] = EndUserAddress.find(:all, :conditions => ["end_user_id in (?) AND end_users.#{address_type} = end_user_addresses.id", ids  ],:joins => :end_user).index_by(&:end_user_id) if address_type

   end
   data
  end


  def self.field_output(user, handler_data, field)
    prefix = field.to_s.split("_")[0]

    if handler_data[prefix]
      UserSegment::FieldType.field_output(user, handler_data[prefix],field)
    else 
      ""
    end
  end


end
