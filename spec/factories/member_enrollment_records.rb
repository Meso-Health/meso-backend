FactoryBot.define do
  factory :member_enrollment_record do
    id { SecureRandom.uuid }
    enrolled_at { Time.zone.now }
    enrollment_period { build(:enrollment_period) }
    member
    user { build(:user, :enrollment) }
    needs_review { false }
    photo { File.open(Rails.root.join("spec/factories/members/photo#{rand(12)+1}.jpg")) }
    absentee { false }

    trait :with_note do
      needs_review { true }
      note { 'Please review member' }
    end

    trait :absentee do
      absentee { true }
      photo { nil }
      member { build(:member, fingerprints_guid: nil, photo: nil) }
    end
  end
end
