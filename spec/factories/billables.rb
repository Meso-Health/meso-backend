FactoryBot.define do
  factory :billable do
    id { SecureRandom.uuid }
    type { Billable::TYPES.sample }
    name { Faker::Commerce.product_name }
    accounting_group { nil }
    active { true }
    reviewed { true }

    trait :with_composition do
      composition { 'tablet' }
    end

    trait :requires_lab_result do
      requires_lab_result { true }
      type { 'lab' }
    end
  end
end
