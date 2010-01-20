# Copyright (C) 2009 Pascal Rettig.

module VerifiedModel #:nodoc:all
  

  def VerifiedModel.append_features(mod)
    super
    mod.extend VerifiedModelClassFunctions
  end

end

module VerifiedModelClassFunctions
  
  def generate_verification_string(length = 30)
    verification_characters = %w(1 2 3 4 5 6 7 8 9 1 2 3 4 5 6 7 8 9 1 2 3 4 5 6 7 8 9 1 2 3 4 5 6 7 8 9 A B C D E F G H I K L M N P Q R S T W X Y Z)
    verification_num_length = verification_characters.length
    
    (0..length).map { |elem| verification_characters[rand(verification_num_length)] }.join
  end
end
