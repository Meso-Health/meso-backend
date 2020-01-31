FactoryBot.define do
  factory :membership_payment do
    id { SecureRandom.uuid }
    receipt_number { rand(10) + 1 }
    payment_date { (rand(60) + 1).months.ago }
    household_enrollment_record { build(:household_enrollment_record) }
  end

  trait :for_renewal do
    annual_contribution_fee { 24000 }
  end

  trait :for_new_enrollment do
    registration_fee { 1000 }
  end
end
