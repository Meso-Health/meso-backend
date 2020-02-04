FactoryBot.define do
  PROVIDER_TYPES = %w[health_center primary_hospital general_hospital tertiary_hospital unclassified]

  factory :provider do
    name { "#{Faker::Company.name} Health Centre #{[3,4,5].sample}" }
    provider_type { PROVIDER_TYPES.sample }
    diagnoses_group_id { nil }
    administrative_division { build(:administrative_division) }
  end
end
