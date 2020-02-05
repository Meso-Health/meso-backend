# This factory (and related factories) have been designed to meet the following timestamp order:
# inbound_referral_date <= encounter.occurred_at <= referral.date <= encounter.prepared_at <= encounter.submitted_at
# <= encounter.adjudicated_at <= (resubmission.prepared_at = resubmission.submitted_at <= resubmission.adjudicated_at) <= now

FactoryBot.define do
  VISIT_REASONS = %w[referral no_referral self_referral follow_up emergency]
  VISIT_TYPES = ['OPD - New Visit', 'OPD - Repeat Visit', 'Inpatient (IPD)']
  PATIENT_OUTCOMES = %w[cured_or_discharged follow_up deceased other]

  factory :encounter do
    id { SecureRandom.uuid }
    provider
    user { build(:user, :provider_admin, provider: provider) }
    member
    occurred_at { rand(6.months).seconds.ago }
    prepared_at { [occurred_at + rand(1.day).seconds, Time.zone.now].min }
    submitted_at { [prepared_at + rand(1.day).seconds, Time.zone.now].min }
    identification_event { build(:identification_event, provider: provider, user: user, member: member, occurred_at: occurred_at) }
    visit_type { VISIT_TYPES.sample }
    submission_state { 'submitted' }
    adjudication_state { 'pending' }
    claim_id { id }
    provider_comment { Faker::Lorem::sentence }
    patient_outcome { PATIENT_OUTCOMES.sample }
    custom_reimbursal_amount { nil }
    visit_reason { (VISIT_REASONS - %w[referral]).sample }
    inbound_referral_date { nil }
    reimbursement { nil }
    discharge_date { nil }

    trait :backdated do
      backdated_occurred_at { true }
      prepared_at { [occurred_at + rand(1.day.seconds..1.month.seconds), Time.zone.now].min }
      identification_event { build(:identification_event, provider: provider, user: user, member: member, occurred_at: prepared_at - rand(1.day).seconds) }
    end

    trait :with_inbound_referral_date do
      visit_reason { 'referral' }
      inbound_referral_date { rand(6.months).seconds.ago }
      occurred_at { [inbound_referral_date + rand(1.month).seconds, Time.zone.now].min }
    end

    trait :with_discharge_date do
      visit_type { 'Inpatient (IPD)' }
      discharge_date { [occurred_at + rand(3.days).seconds, Time.zone.now].min }
      prepared_at { [discharge_date + rand(1.day).seconds, Time.zone.now].min }
    end

    trait :with_bypass_fee do
      after(:create) do |record|
        record.update_attributes(custom_reimbursal_amount: record.price / 2)
      end
    end

    trait :with_items do
      transient do
        items_count { 2 }
        price { rand(20000) + 5000 }
      end

      after(:create) do |record, evaluator|
        remaining_price = evaluator.price
        count = evaluator.items_count
        item_price = evaluator.price / count

        (count - 1).times do
          remaining_price -= item_price
          record.encounter_items << create(:encounter_item, encounter: record, quantity: 1, price_schedule: create(:price_schedule, provider: evaluator.provider, price: item_price))
        end

        record.encounter_items << create(:encounter_item, encounter: record, quantity: 1, price_schedule: create(:price_schedule, provider: evaluator.provider, price: remaining_price))
      end
    end

    trait :with_specified_items do
      # Note: these billables must have at least 1 price schedule associated
      transient do
        billables { [] }
        stockout { false }
      end

      after(:create) do |record, evaluator|
        billables = evaluator.billables

        unless billables.empty?
          billable_indices = [*(0..billables.count - 1)]
          # randomly select a few billables to be stocked out
          stockout_indices = evaluator.stockout ? [*billable_indices.sample(rand(1..billables.count))] : []
          # for 1 in 5 encounters, randomly select one billable to have an updated price schedule
          updated_price_schedule_indices = rand < 0.2 ? [billable_indices.sample] : []

          billables.each_with_index do |billable, index|
            is_stockout = stockout_indices.include?(index)
            update_price_schedule = updated_price_schedule_indices.include?(index)

            old_price_schedule = billable.active_price_schedule_for_provider(record.provider_id)
            billable.price_schedules << create(:price_schedule, :for_previous, previous_price_schedule: old_price_schedule) if update_price_schedule
            record.encounter_items << create(:encounter_item, encounter: record, price_schedule_issued: update_price_schedule, price_schedule: billable.active_price_schedule_for_provider(record.provider_id), stockout: is_stockout)
          end
        end
      end
    end

    trait :with_referrals do
      patient_outcome { 'referred' }

      transient do
        items_count { 2 }
      end

      after(:create) do |record, evaluator|
        evaluator.items_count.times do
          record.referrals << create(:referral, encounter: record)
        end
      end
    end

    trait :with_specified_referrals do
      patient_outcome { 'referred' }

      transient do
        referrals { [] }
      end

      after(:create) do |record, evaluator|
        record.referrals << evaluator.referrals
      end
    end

    trait :with_diagnoses do
      transient do
        diagnoses_count { 2 }
      end

      after(:build) do |record, evaluator|
        evaluator.diagnoses_count.times { record.diagnoses << create(:diagnosis) }
      end
    end

    trait :with_specified_diagnoses do
      transient do
        diagnoses { [] }
      end

      after(:build) do |record, evaluator|
        record.diagnoses << evaluator.diagnoses
      end
    end

    trait :with_forms do
      transient do
        forms_count { 2 }
      end

      after(:build) do |record, evaluator|
        evaluator.forms_count.times do |i|
          record.add_form(File.open(Rails.root.join("spec/factories/encounters/form#{i+1}.jpg")))
        end
      end
    end

    trait :from_hospital do
      provider { build(:provider, provider_type: %w[primary_hospital general_hospital tertiary_hospital].sample) }
    end

    trait :started do
      from_hospital
      user { build(:user, :identification, provider: provider) }
      submission_state { 'started' }
      adjudication_state { nil }
      prepared_at { nil }
      submitted_at { nil }
    end

    trait :prepared do
      from_hospital
      user { build(:user, :submission, provider: provider) }
      submission_state { 'prepared' }
      adjudication_state { nil }
      submitted_at { nil }
      visit_type { nil }
      provider_comment { nil }
      patient_outcome { nil }

    end

    trait :needs_revision do
      from_hospital
      user { build(:user, :provider_admin, provider: provider) }
      submission_state { 'needs_revision' }
      adjudication_state { nil }
      submitted_at { nil }
    end

    trait :submitted
    trait :pending

    trait :returned do
      adjudication_state { 'returned' }
      adjudicator { build(:user, :adjudication) }
      adjudicated_at { [submitted_at + rand(2.weeks).seconds, Time.zone.now].min }
      adjudication_reason_category { Faker::Lorem::word }
      adjudication_comment { Faker::Lorem::sentence }
    end

    trait :approved do
      adjudication_state { 'approved' }
      adjudicator { build(:user, :adjudication) }
      adjudicated_at { [submitted_at + rand(2.weeks).seconds, Time.zone.now].min }
    end

    trait :rejected do
      adjudication_state { 'rejected' }
      adjudicator { build(:user, :adjudication) }
      adjudicated_at { [submitted_at + rand(2.weeks).seconds, Time.zone.now].min }
      adjudication_reason_category { Faker::Lorem::word }
      adjudication_comment { Faker::Lorem::sentence }
    end

    trait :revised do
      adjudication_state { 'revised' }
      adjudicator { build(:user, :adjudication) }
      adjudicated_at { [submitted_at + rand(2.weeks).seconds, Time.zone.now].min }
      adjudication_reason_category { Faker::Lorem::word }
      adjudication_comment { Faker::Lorem::sentence }
    end

    trait :external do
      adjudication_state { 'external' }
    end

    trait :resubmitted do
      returned

      after(:build) do |record|
        record.resubmitted_encounter = build(:encounter, :resubmission, revised_encounter: record)
      end
    end

    trait :resubmission do
      revised_encounter { build(:encounter, :returned) }
      claim_id { revised_encounter.claim_id }
      provider { revised_encounter.provider }
      user { revised_encounter.user }
      member { revised_encounter.member }
      identification_event { revised_encounter.identification_event }
      occurred_at { revised_encounter.occurred_at }
      prepared_at { [revised_encounter.adjudicated_at + rand(2.weeks).seconds, Time.zone.now].min }
      submitted_at { prepared_at } # submitted_at is always the same as prepared_at for resubmissions
    end

    trait :reimbursed do
      approved

      after(:create) do |record|
        create(:reimbursement, encounters: [record], provider: record.provider, total: record.reimbursal_amount)
      end
    end

    trait :audited do
      audited_at { [submitted_at + rand(1.day).seconds, Time.zone.now].min }
    end
  end
end
