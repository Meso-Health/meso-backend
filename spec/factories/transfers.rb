FactoryBot.define do
  factory :transfer do
    description { Faker::Lorem.sentence }
    amount { 10_00 + Random.rand(10_000_00) }
    stripe_account_id { "acct_#{Faker::Lorem.characters(number: 16)}" }
    stripe_transfer_id { "tr_#{Faker::Lorem.characters(number: 14)}" }
    stripe_payout_id { "po_#{Faker::Lorem.characters(number: 24)}" }
    initiated_at { Time.zone.now }
    user
  end

  trait :payout_failed do
    stripe_payout_id { nil }
  end
end
