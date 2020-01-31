FactoryBot.define do
  factory :card_batch do
    prefix { CardIdGenerator.random_prefix }
    reason { Faker::Company.catch_phrase }
  end
end
