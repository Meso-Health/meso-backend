FactoryBot.define do
  factory :member do
    id { SecureRandom.uuid }
    enrolled_at { Time.zone.now }
    card
    household
    full_name { Faker::Name.name_with_middle }
    gender { %w[M F].sample }
    birthdate { (rand(60) + 1).years.ago }
    birthdate_accuracy { 'Y' }
    preferred_language { (Member::PREFERRED_LANGUAGE_CHOICES - %w[other]).sample }
    phone_number { [0, rand(9) + 1, rand.to_s[2..9]].join }
    profession { %w[FARMER STUDENT MERCHANT JOB_SEEKER DISABLED].sample }
    relationship_to_head { %w[SPOUSE CHILD PARENT GRANDCHILD GRANDPARENT HOUSE_STAFF OTHER].sample }
    photo { File.open(Rails.root.join("spec/factories/members/photo#{rand(12)+1}.jpg")) }
    fingerprints_guid { SecureRandom.uuid }
    membership_number { SecureRandom.alphanumeric(MembershipNumberService::DEFAULT_MEMBERSHIP_NUMBER_LENGTH).upcase! }
    medical_record_numbers {
      {
        "primary": Faker::Number.leading_zero_number(digits: 5).to_s,
        "1": Faker::Number.leading_zero_number(digits: 5).to_s,
        "2": Faker::Number.leading_zero_number(digits: 5).to_s,
        "3": Faker::Number.leading_zero_number(digits: 5).to_s,
        "4": Faker::Boolean.boolean ? Faker::Number.leading_zero_number(digits: 5).to_s : nil,
        "5": Faker::Boolean.boolean ? Faker::Number.leading_zero_number(digits: 5).to_s : nil,
        "6": Faker::Boolean.boolean ? Faker::Number.leading_zero_number(digits: 5).to_s : nil,
        "7": Faker::Boolean.boolean ? Faker::Number.leading_zero_number(digits: 5).to_s : nil,
        "8": Faker::Boolean.boolean ? Faker::Number.leading_zero_number(digits: 5).to_s : nil,
      }
    }

    trait :unconfirmed do
      household { nil }
    end

    trait :no_card_issued do
      card { nil }
    end

    trait :birthdate_accurate_to_month do
      birthdate_accuracy { 'M' }
    end

    trait :birthdate_accurate_to_day do
      birthdate_accuracy { 'D' }
    end

    trait :with_national_id_photo do
      national_id_photo { File.open(Rails.root.join("spec/factories/members/national_id_photo#{rand(4)+1}.jpg")) }
    end

    trait :absentee do
      photo { nil }
      fingerprints_guid { nil }
    end

    trait :archived do
      archived_at { Time.zone.now }
      archived_reason { 'deceased' }
    end

    trait :unpaid do
      archived_at { Time.zone.now }
      archived_reason { Member::UNPAID_ARCHIVED_REASON }
    end

    trait :head_of_household do
      relationship_to_head { 'SELF' }
      profession { %w[FARMER MERCHANT JOB_SEEKER].sample }
      birthdate { (18..80).to_a.sample.years.ago }
    end

    trait :beneficiary do
      relationship_to_head { %w[CHILD PARENT GRANDCHILD GRANDPARENT HOUSE_STAFF OTHER].sample }
      profession { %w[FARMER STUDENT MERCHANT JOB_SEEKER].sample }
    end

    trait :spouse do
      relationship_to_head { 'SPOUSE' }
      birthdate { (18..80).to_a.sample.years.ago }
      gender { %w[M F].sample }
    end

    trait :child do
      relationship_to_head { %w[CHILD OTHER].sample }
      birthdate { (0..17).to_a.sample.years.ago }
    end
  end
end
