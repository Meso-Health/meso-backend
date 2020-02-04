FactoryBot.define do
  factory :card do
    id { CardIdGenerator.unique }
    card_batch

    trait :revoked do
      revoked_at { Time.zone.now }
    end
  end
end
