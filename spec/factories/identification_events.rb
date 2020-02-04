FactoryBot.define do
  factory :identification_event do
    id { SecureRandom.uuid }
    occurred_at { rand(6.months).seconds.ago }
    provider
    member
    user
    clinic_number { rand(1000) }
    clinic_number_type { IdentificationEvent::CLINIC_NUMBER_TYPES.sample }
    accepted { true }
    search_method { (IdentificationEvent::SEARCH_METHODS - %w[through_household]).sample }
    photo_verified { true }

    trait :through_household do
      association :through_member, factory: :member
    end

    trait :dismissed do
      dismissed { true }
      dismissal_reason { IdentificationEvent::DISMISSAL_REASONS.keys.sample }
    end
  end
end
