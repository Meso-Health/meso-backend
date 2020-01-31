FactoryBot.define do
  factory :authentication_token do
    id { SecureRandom.base58(8) }
    secret_digest { ::Digest::SHA256.hexdigest(secret) }
    expires_at { 2.weeks.from_now }
    user

    transient do
      secret { SecureRandom.base58(32) }
    end

    trait :revoked do
      revoked_at { Time.zone.now }
    end
  end
end
