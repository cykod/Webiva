
module ModelExtension::EndUserExtension
  module ClassMethods
    def after_save_update_end_user_name(end_user_field, name_column)
      after_save "post_process_save_end_user_name_#{end_user_field}_#{name_column}"

      define_method("post_process_save_end_user_name_#{end_user_field}_#{name_column}")  do
        post_process_save_end_user_name(end_user_field, name_column)
      end
    end
  end

  def self.append_features(mod) #:nodoc:
    super
    mod.extend ModelExtension::EndUserExtension::ClassMethods
  end

  def post_process_save_end_user_name(end_user_field, name_column)
    user = self.send(end_user_field)
    user.update_name(self.send(name_column)) if user
  end
end
