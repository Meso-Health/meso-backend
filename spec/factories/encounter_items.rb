FactoryBot.define do
  factory :encounter_item do
    id { SecureRandom.uuid }
    encounter
    price_schedule { build(:price_schedule, provider: encounter.try(:provider)) }
    quantity { rand(10) + 1 }

    trait :with_lab_result do
      transient do
        lab_result
      end

      after(:build) do |record, evaluator|
        record.lab_result = build(:lab_result, encounter_item: record)
      end
    end
  end
end
