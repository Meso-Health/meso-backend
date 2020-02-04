FactoryBot.define do
  factory :diagnosis do
    description { Faker::Lorem::sentence }
    active { true }
  end
end
