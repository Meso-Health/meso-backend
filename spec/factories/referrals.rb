FactoryBot.define do
  factory :referral do
    REASONS = %w[further_consultation drug_stockout investigative_tests inpatient_care bed_shortage follow_up other]
    id { SecureRandom.uuid }
    encounter
    receiving_facility { "#{Faker::Company.name} Health Centre #{[3, 4, 5].sample}" }
    # referral should always be equal to or between when an encounter occurred and when it was submitted
    date { rand(encounter.occurred_at..encounter.prepared_at) }
    number { Faker::Number.leading_zero_number(digits: 5) }
    reason { REASONS.sample }

    trait :follow_up do
      receiving_facility { "SELF" }
    end
  end
end
