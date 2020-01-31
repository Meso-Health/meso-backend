FactoryBot.define do
  factory :reimbursement do
    id { SecureRandom.uuid }
    provider
    user { build(:user, :payer_admin) }
    total { rand(10) + 1 }
    completed_at { nil }
    payment_date { nil }
    payment_field { nil }
    transient do
      encounter_count { 1 }
    end
    encounters { build_list(:encounter, encounter_count, :approved, provider: provider, user: user) }

    after(:create) do |reimbursement, evaluator|
      PaperTrail.without_versioning do
        reimbursement.update!(total: evaluator.encounters.map(&:reimbursal_amount).sum)
      end
    end
  end

  trait :completed do
    completed_at { 1.days.ago }
    payment_date { 1.days.ago }
    payment_field {
      if [true, false].sample
        {
          bank_transfer_number: Faker::Number.leading_zero_number(digits: 8),
          bank_name: Faker::Bank.name,
          bank_account_number: Faker::Number.leading_zero_number(digits: 12),
          payer_bank_account_number: Faker::Number.leading_zero_number(digits: 12),
          bank_approver_name: Faker::Name.name,
          bank_internal_voucher_number: Faker::Number.leading_zero_number(digits: 8)
        }
      else
        {
          check_number: Faker::Number.leading_zero_number(digits: 4),
          check_approver_name: Faker::Name.name,
          check_internal_voucher_number: Faker::Number.leading_zero_number(digits: 8),
          designated_person: Faker::Name.name
        }
      end
    }
  end
end
