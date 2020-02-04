module DataGenerator
  ANNUAL_CONTRIBUTION_FEE = 3_000
  BENEFICIARY_FEE = 100
  REASONS = %w[further_consultation investigative_tests inpatient_care bed_shortage follow_up other]

  # generates MSO000001 - MSO000#{count}
  def generate_cards(count, prefix: 'MSO')
    card_batch = create(:card_batch, prefix: prefix, reason: 'enrollment')
    count.times do |index|
      card_id = "#{card_batch.prefix}#{(index + 1).to_s.rjust(6, '0')}"
      create(:card, id: card_id, card_batch: card_batch)
    end
  end

  def generate_cards_with_fixed_ids(card_ids, prefix: 'MSO')
    card_batch = create(:card_batch, prefix: prefix, reason: 'enrollment')
    card_ids.each do |card_id|
      create(:card, id: card_id, card_batch: card_batch)
    end
  end

  def generate_household(village, enroller, household_size:, paying:, renewed:, include_member_photos:)
    raise ArgumentError, 'Household size must be 1 or more' if household_size < 1

    # Generate household and original household enrollment record (set to have been created during first enrollment period)
    original_enrollment_period = EnrollmentPeriod.inactive.first
    original_enrolled_at = rand(original_enrollment_period.start_date..original_enrollment_period.end_date)
    household = create(:household, administrative_division: village, enrolled_at: original_enrolled_at)
    original_enrollment = create(
      :household_enrollment_record, household: household, administrative_division: village,
      enrollment_period: original_enrollment_period, enrolled_at: original_enrolled_at, user: enroller, paying: paying, renewal: false
    )
    if paying
      create(:membership_payment, household_enrollment_record: original_enrollment, annual_contribution_fee: ANNUAL_CONTRIBUTION_FEE, qualifying_beneficiaries_fee: BENEFICIARY_FEE * household_size)
    end

    # Generate members and member enrollment records
    generate_household_members(household, original_enrollment_period, enroller, household_size: household_size, include_member_photos: include_member_photos)

    # For renewed households, generate additional household enrollment record for the current enrollment period
    if renewed
      current_enrollment_period = EnrollmentPeriod.active_now.first
      # Ensure renewals occur within past week so that renewed households appear in recently updated page in Enrollment App
      renewed_at = rand(1.week.ago.to_date..Time.zone.now.to_date)
      renewal = create(
        :household_enrollment_record, household: household, administrative_division: village,
        enrollment_period: current_enrollment_period, enrolled_at: renewed_at, user: enroller, paying: paying, renewal: true
      )
      if paying
        create(:membership_payment, household_enrollment_record: renewal, annual_contribution_fee: ANNUAL_CONTRIBUTION_FEE)
      end
    end
  end

  def generate_id_events_and_encounters(provider, provider_user, adjudicator)
    # Create dismissed id events
    2.times do
      create(:identification_event, :dismissed, provider: provider, user: provider_user, member: random_member)
    end

    # Create pending claims
    2.times do
      create(:encounter, :with_specified_items, **encounter_attributes(provider, provider_user))
    end

    # Create backdated pending claims
    2.times do
      create(:encounter, :backdated, :with_specified_items, **encounter_attributes(provider, provider_user))
    end

    # Create rejected claims
    2.times do
      create(:encounter, :rejected, :with_specified_items, **encounter_attributes(provider, provider_user), adjudicator: adjudicator)
    end

    # Create approved claims
    5.times do
      create(:encounter, :approved, :with_specified_items, **encounter_attributes(provider, provider_user), adjudicator: adjudicator)
    end

    # Create returned claims
    5.times do
      create(:encounter, :returned, :with_specified_items, **encounter_attributes(provider, provider_user), adjudicator: adjudicator)
    end

    # Create pending resubmissions (chain size: 2)
    2.times do
      billables = provider.billables.sample(rand(1..5))
      encounter1 = create(:encounter, :returned, :with_specified_items, **encounter_attributes(provider, provider_user, billables: billables), adjudicator: adjudicator)
      create(:encounter, :resubmission, :with_specified_items, billables: billables, revised_encounter: encounter1)
    end

    # Create approved resubmissions (chain size: 2)
    2.times do
      billables = provider.billables.sample(rand(1..5))
      encounter1 = create(:encounter, :returned, :with_specified_items, **encounter_attributes(provider, provider_user, billables: billables), adjudicator: adjudicator)
      create(:encounter, :resubmission, :approved, :with_specified_items, billables: billables, revised_encounter: encounter1, adjudicator: adjudicator)
    end

    # Create returned resubmissions (chain size: 2)
    2.times do
      billables = provider.billables.sample(rand(1..5))
      encounter1 = create(:encounter, :returned, :with_specified_items, **encounter_attributes(provider, provider_user, billables: billables), adjudicator: adjudicator)
      create(:encounter, :resubmission, :returned, :with_specified_items, billables: billables, revised_encounter: encounter1, adjudicator: adjudicator)
    end

    # Create pending resubmissions of resubmissions (chain size: 3)
    2.times do
      billables = provider.billables.sample(rand(1..5))
      encounter1 = create(:encounter, :returned, :with_specified_items, **encounter_attributes(provider, provider_user, billables: billables), adjudicator: adjudicator)
      encounter2 = create(:encounter, :resubmission, :returned, :with_specified_items, billables: billables, revised_encounter: encounter1, adjudicator: adjudicator)
      create(:encounter, :resubmission, :with_specified_items, billables: billables, revised_encounter: encounter2)
    end

    # Create claims within 30 days for a single member
    member = random_member
    create(:encounter, :with_specified_items, **encounter_attributes(provider, provider_user, member: member), occurred_at: 20.days.ago)
    create(:encounter, :with_specified_items, **encounter_attributes(provider, provider_user, member: member), occurred_at: 10.days.ago)
    create(:encounter, :with_specified_items, **encounter_attributes(provider, provider_user, member: member), occurred_at: 3.days.ago)
    create(:encounter, :with_specified_items, **encounter_attributes(provider, provider_user, member: member), occurred_at: 1.day.ago)
    create(:encounter, :with_specified_items, **encounter_attributes(provider, provider_user, member: member), occurred_at: 1.hour.ago)
  end

  def generate_hospital_id_events_and_partial_encounters(provider, card_room_user, claims_preparer_user, facility_head_user)
    # Create open id events with started encoutners
    5.times do
      create(:encounter, :started, provider: provider, user: card_room_user, member: random_member)
    end

    # Create prepared encounters
    5.times do
      create(:encounter, :prepared, :with_specified_items, **encounter_attributes(provider, claims_preparer_user))
    end

    # Create facility head returned encoutners
    5.times do
      create(:encounter, :needs_revision, :with_specified_items, **encounter_attributes(provider, facility_head_user))
    end
  end

  def generate_stockouts_and_referrals(provider, provider_user, receiving_facility, receiving_facility_user, adjudicator)
    # CLAIMS FOR REFERRING CLINIC

    # Create pending claims and 10 approved claims with stockouts but no referrals
    5.times do
      create(:encounter, :with_specified_items, **encounter_attributes(provider, provider_user), stockout: true)
      create(:encounter, :approved, :with_specified_items, **encounter_attributes(provider, provider_user), stockout: true, adjudicator: adjudicator)
    end

    # Create pending claims and 10 approved claims with stockouts and referrals
    5.times do
      pending_encounter = create(:encounter, :with_specified_items, **encounter_attributes(provider, provider_user), stockout: true, patient_outcome: 'referred')
      approved_encounter = create(:encounter, :approved, :with_specified_items, **encounter_attributes(provider, provider_user), stockout: true, adjudicator: adjudicator, patient_outcome: 'referred')
      create(:referral, encounter: pending_encounter, reason: 'drug_stockout', receiving_facility: receiving_facility.name)
      create(:referral, encounter: approved_encounter, reason: 'drug_stockout', receiving_facility: receiving_facility.name)
    end

    # Create pending / approved claims with non-stockout referrals
    5.times do
      pending_encounter = create(:encounter, :with_specified_items, **encounter_attributes(provider, provider_user), patient_outcome: 'referred')
      approved_encounter = create(:encounter, :approved, :with_specified_items, **encounter_attributes(provider, provider_user), adjudicator: adjudicator, patient_outcome: 'referred')
      create(:referral, encounter: pending_encounter, reason: REASONS.sample, receiving_facility: receiving_facility.name)
      create(:referral, encounter: approved_encounter, reason: REASONS.sample, receiving_facility: receiving_facility.name)
    end

    # Create pending / approved claims with referrals (using receiving facility so that the followup is within same place)
    5.times do
      pending_encounter = create(:encounter, :with_specified_items, **encounter_attributes(receiving_facility, receiving_facility_user), patient_outcome: 'follow_up')
      approved_encounter = create(:encounter, :approved, :with_specified_items, **encounter_attributes(receiving_facility, receiving_facility_user), adjudicator: adjudicator, patient_outcome: 'follow_up')
      create(:referral, :follow_up, encounter: pending_encounter, reason: REASONS.sample)
      create(:referral, :follow_up, encounter: approved_encounter, reason: REASONS.sample)
    end

    # CLAIMS FOR RECEIVING HOSPITAL

    # Create pending claims with linkable inbound referrals
    Referral.all.sample(10).each do |referral|
      encounter = create(:encounter, :with_inbound_referral_date, :with_specified_items, **encounter_attributes(receiving_facility, receiving_facility_user), member: referral.encounter.member, inbound_referral_date: referral.date)
      ReferralMatchingService.new.match_from_inbound_referral_date!(encounter)
      encounter.reload
    end

    # Create pending claims with un-linkable inbound referrals
    2.times do
      create(:encounter, :with_inbound_referral_date, :with_specified_items, **encounter_attributes(receiving_facility, receiving_facility_user))
    end

    # Create 5 pending claims with no referrals
    2.times do
      create(:encounter, :with_specified_items, **encounter_attributes(receiving_facility, receiving_facility_user))
    end

    # Create pending claims with no referrals and custom reimbursable amount
    2.times do
      encounter = create(:encounter, :with_specified_items, **encounter_attributes(receiving_facility, receiving_facility_user))
      encounter.update!(custom_reimbursal_amount: rand(1..encounter.price))
    end
  end

  def generate_reimbursements(provider, provider_user, adjudicator, reimburser)
    encounters = create_list(:encounter, 45, :approved, :with_specified_items, **encounter_attributes(provider, provider_user), adjudicator: adjudicator)

    create(:reimbursement, :completed, encounters: encounters.pop(20), provider: provider, user: reimburser)
    create(:reimbursement, :completed, encounters: encounters.pop(15), provider: provider, user: reimburser)
    create(:reimbursement, :completed, encounters: encounters.pop(10), provider: provider, user: reimburser)
  end

  protected

  def random_member
    Member.order('RANDOM()').limit(1).first
  end

  def random_diagnoses(provider)
    provider.diagnoses.sample(2)
  end

  def encounter_attributes(provider, user, billables: nil, member: nil)
    {
      billables: billables || provider.billables.sample(5),
      diagnoses: random_diagnoses(provider),
      provider: provider,
      user: user,
      member: member || random_member,
      provider_comment: nil
    }
  end

  def generate_household_members(household, enrollment_period, enroller, household_size:, include_member_photos:)
    head_of_household_gender = %w[M F].sample

    household_size.times do |i|
      member_attributes = {
        household: household,
        enrolled_at: household.enrolled_at,
        membership_number: nil, # will be automatically assigned upon creation of member enrollment record
        card: Card.unassigned.order(:id).first # assign cards in id order
      }
      member_attributes[:photo_id] = nil unless include_member_photos

      member =
        case i
        when 0
          create(:member, :head_of_household, gender: head_of_household_gender, **member_attributes)
        when 1
          create(:member, :spouse, **member_attributes)
        else
          create(:member, :beneficiary, **member_attributes)
        end

      # .reload is necessary to refresh the member's household so that it reflects newly assigned membership numbers
      # (specifically so that household.assigned_membership_numbers? works as intended and membership numbers are generated properly)
      create(:member_enrollment_record, member: member.reload, enrollment_period: enrollment_period, user: enroller)
    end
  end
end
