FactoryBot.define do
  factory :enrollment_period do
    start_date { 4.weeks.ago }
    end_date { 3.weeks.ago }
    coverage_start_date { start_date }
    coverage_end_date { end_date }
    administrative_division

    trait :in_progress do
      start_date { 1.days.ago } # Both of these are needed to prevent factory defaults to overlap with an :in_progress enrollment period.
      end_date { 5.days.from_now }
    end
  end
end
