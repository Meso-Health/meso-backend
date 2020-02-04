FactoryBot.define do
  factory :lab_result do
    id { SecureRandom.uuid }
    encounter_item { build(:encounter_item) }
    result { LabResult::RESULTS.sample }
  end
end
