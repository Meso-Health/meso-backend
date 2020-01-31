FactoryBot.define do
  factory :household do
    id { SecureRandom.uuid }
    enrolled_at { Time.zone.now }
    photo { File.open(Rails.root.join("spec/factories/households/photo#{rand(3)+1}.jpg")) }
    latitude { Faker::Address.latitude }
    longitude { Faker::Address.longitude }
    administrative_division { build(:administrative_division) }
    address { Faker::Number.leading_zero_number(digits: 5) }

    trait :with_members do
      transient do
        members_count { 2 }
      end

      after(:create) do |record, evaluator|
        record.members << create_list(:member, evaluator.members_count, household: record)
      end
    end
  end
end
