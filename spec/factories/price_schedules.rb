FactoryBot.define do
  factory :price_schedule do
    id { SecureRandom.uuid }
    provider
    price { rand(1..100) * 100 }
    billable { build(:billable) }
    issued_at { 5.hours.ago }

    trait :with_previous do
      previous_price_schedule { build(:price_schedule, provider: provider, billable: billable, issued_at: 6.hours.ago) }
    end

    trait :for_previous do
      previous_price_schedule { build(:price_schedule) }
      provider { previous_price_schedule.provider }
      billable { previous_price_schedule.billable }
      price { ((rand * 2) * previous_price_schedule.price).to_i }
      issued_at { Time.zone.now }
    end
  end
end
