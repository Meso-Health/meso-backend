FactoryBot.define do
  factory :household_enrollment_record do
    id { SecureRandom.uuid }
    enrolled_at { Time.zone.now }
    enrollment_period { build(:enrollment_period, :in_progress) }
    declined { false }
    paying { Faker::Boolean.boolean(true_ratio: 0.8) }
    renewal { Faker::Boolean.boolean(true_ratio: 0.8) }
    household { build(:household, administrative_division: administrative_division) }
    user { build(:user, :enrollment) }
    administrative_division { build(:administrative_division) }

    trait :with_membership_payments do
      paying { true }

      transient do
        payments_count { 1 }
      end

      after(:build) do |record, evaluator|
        evaluator.payments_count.times do
          record.membership_payments << [
            build(:membership_payment, :for_renewal, household_enrollment_record: record),
            build(:membership_payment, :for_new_enrollment, household_enrollment_record: record)
          ].sample(1)
        end
      end
    end
  end
end
