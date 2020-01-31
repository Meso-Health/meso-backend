FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    username { Faker::Internet.unique.user_name }
    role { 'system_admin' }
    password { 'password' }

    trait :system_admin do
      role { 'system_admin' }
    end

    trait :payer_admin do
      role { 'payer_admin' }
    end

    trait :adjudication do
      role { 'adjudication' }
    end

    trait :enrollment do
      role { 'enrollment' }
      administrative_division { build(:administrative_division) }
    end

    trait :provider_admin do
      role { 'provider_admin' }
      provider
    end

    trait :identification do
      role { 'identification' }
      provider
    end

    trait :submission do
      role { 'submission' }
      provider
    end

    trait :deleted do
      deleted_at { Time.zone.now }
    end
  end
end
