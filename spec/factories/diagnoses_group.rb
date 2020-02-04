FactoryBot.define do
  factory :diagnoses_group do
    name { Faker::Lorem::word }
    diagnoses { create_list(:diagnosis, 3) }
  end
end
