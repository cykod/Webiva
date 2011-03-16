


Factory.define :end_user do |eu|
  eu.sequence(:email) { |n| "test_user#{n}@webiva.org" }
  eu.sequence(:first_name) { |n| "user#{n}" }
  eu.last_name "tester"
  eu.user_class_id { UserClass.default_user_class_id }

end
