
class EndUserAddressSegmentType

  class AddressBaseType < UserSegment::FieldType
    def self.address_field_name(user_field_name) 
      register_operation :like, [['String', :string]], :name => 'Contains', :description => 'use % for wild card matches'

      sing = class << self; self; end

      sing.send(:define_method, :user_field_name) do
        user_field_name
      end
    end

    def self.like(cls, group_field, field, string)
      cls.scoped(:conditions => ["#{field} like ? AND end_users.#{self.user_field_name} = end_user_addresses.id", "%" + string.to_s + "%" ],:joins => :end_user)
    end

  end

  class AddressStringType < AddressBaseType
    address_field_name  :address_id
  end

 class WorkAddressStringType < AddressBaseType
   address_field_name :work_address_id
 end


end
