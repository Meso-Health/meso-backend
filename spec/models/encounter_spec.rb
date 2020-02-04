require 'rails_helper'

RSpec.describe Encounter, type: :model do
  describe 'when creating the record' do
    let!(:returned_encounter) { create(:encounter, :returned) }
    subject { create(:encounter, revised_encounter: returned_encounter) }

    it 'sets the returned encounter to revised' do
      expect(subject.revised_encounter).to be_revised
      expect(subject).to be_pending
    end
  end

  describe 'validations' do
    describe 'custom_reimbursal_amount' do
      it 'does not allow negative or decimal amounts' do
        expect(build(:encounter, custom_reimbursal_amount: -1)).to_not be_valid
        expect(build(:encounter, custom_reimbursal_amount: 5.5)).to_not be_valid
      end

      it 'allows 0 or positive custom reimbursal amounts' do
        expect(build(:encounter, custom_reimbursal_amount: 0)).to be_valid
        expect(build(:encounter, custom_reimbursal_amount: 10)).to be_valid
        expect(build(:encounter, custom_reimbursal_amount: 2000)).to be_valid
      end
    end

    describe 'submission_state' do
      it 'does not allow encounter with nil or incorrect submission state' do
        expect(build(:encounter, submission_state: nil)).to_not be_valid
        expect(build(:encounter, submission_state: 'disco')).to_not be_valid
      end

      describe 'prepared_at' do
        let(:prepared_at) { Time.zone.now }

        it 'is absent if encounter is started' do
          expect(build(:encounter, :started, prepared_at: nil)).to be_valid
          expect(build(:encounter, :started, prepared_at: prepared_at)).to_not be_valid
        end

        it 'is present otherwise' do
          expect(build(:encounter, :prepared, prepared_at: nil)).to_not be_valid
          expect(build(:encounter, :prepared, prepared_at: prepared_at)).to be_valid

          expect(build(:encounter, :needs_revision, prepared_at: nil)).to_not be_valid
          expect(build(:encounter, :needs_revision, prepared_at: prepared_at)).to be_valid

          expect(build(:encounter, :submitted, submitted_at: Time.zone.now, prepared_at: nil)).to_not be_valid
          expect(build(:encounter, :submitted, prepared_at: prepared_at)).to be_valid
        end
      end

      describe 'submitted_at' do
        let(:submitted_at) { Time.zone.now }

        it 'is present if encounter is submitted' do
          expect(build(:encounter, :submitted, submitted_at: nil)).to_not be_valid
          expect(build(:encounter, :submitted, submitted_at: submitted_at)).to be_valid
        end

        it 'is absent otherwise' do
          expect(build(:encounter, :started, submitted_at: nil)).to be_valid
          expect(build(:encounter, :started, submitted_at: submitted_at)).to_not be_valid

          expect(build(:encounter, :prepared, submitted_at: nil)).to be_valid
          expect(build(:encounter, :prepared, submitted_at: submitted_at)).to_not be_valid

          expect(build(:encounter, :needs_revision, submitted_at: nil)).to be_valid
          expect(build(:encounter, :needs_revision, submitted_at: submitted_at)).to_not be_valid
        end
      end

      describe 'adjudication_state' do
        let(:adjudication_state) { 'pending' }

        it 'may be present if encounter is submitted' do
          expect(build(:encounter, :submitted, adjudication_state: adjudication_state)).to be_valid
        end

        it 'is absent otherwise' do
          expect(build(:encounter, :started, adjudication_state: nil)).to be_valid
          expect(build(:encounter, :started, adjudication_state: adjudication_state)).to_not be_valid

          expect(build(:encounter, :prepared, adjudication_state: nil)).to be_valid
          expect(build(:encounter, :prepared, adjudication_state: adjudication_state)).to_not be_valid

          expect(build(:encounter, :needs_revision, adjudication_state: nil)).to be_valid
          expect(build(:encounter, :needs_revision, adjudication_state: adjudication_state)).to_not be_valid
        end
      end
    end

    describe 'adjudication_state' do
      it 'does not allow encounter with incorrect adjudication state' do
        expect(build(:encounter, adjudication_state: 'disco')).to_not be_valid
      end

      describe 'adjudicator and adjudicated_at' do
        let(:adjudicator) { build(:user, :adjudication) }
        let(:adjudicated_at) { Time.zone.now }

        it 'are absent when nil or pending' do
          # adjudication_state is nil for started encounters
          expect(build(:encounter, :started, adjudicator: adjudicator, adjudicated_at: adjudicated_at)).to_not be_valid
          expect(build(:encounter, :started, adjudicator: nil, adjudicated_at: nil)).to be_valid

          expect(build(:encounter, :pending, adjudicator: adjudicator, adjudicated_at: adjudicated_at)).to_not be_valid
          expect(build(:encounter, :pending, adjudicator: nil, adjudicated_at: nil)).to be_valid
        end

        it 'are present otherwise' do
          expect(build(:encounter, :approved, adjudicator: adjudicator, adjudicated_at: adjudicated_at)).to be_valid
          expect(build(:encounter, :approved, adjudicator: nil, adjudicated_at: nil)).to_not be_valid

          expect(build(:encounter, :returned, adjudicator: adjudicator, adjudicated_at: adjudicated_at)).to be_valid
          expect(build(:encounter, :returned, adjudicator: nil, adjudicated_at: nil)).to_not be_valid

          expect(build(:encounter, :rejected, adjudicator: adjudicator, adjudicated_at: adjudicated_at)).to be_valid
          expect(build(:encounter, :rejected, adjudicator: nil, adjudicated_at: nil)).to_not be_valid

          expect(build(:encounter, :revised, adjudicator: adjudicator, adjudicated_at: adjudicated_at)).to be_valid
          expect(build(:encounter, :revised, adjudicator: nil, adjudicated_at: nil)).to_not be_valid
        end
      end
    end
  end

  describe 'scopes' do
    describe '.with_unconfirmed_member' do
      let(:member1) { create(:member) }
      let(:member2) { create(:member, :unconfirmed) }
      let(:encounter1) { create(:encounter, member: member1) }
      let(:encounter2) { create(:encounter, member: member2) }

      it 'returns the encounters with unconfirmed members' do
        expect(described_class.with_unconfirmed_member).to match_array([encounter2])
      end
    end

    describe '.with_inactive_member_at_time_of_service' do
      let(:enrollment_period) do
        create(:enrollment_period,
               start_date: Time.zone.parse('2018/10/01 EAT'),
               end_date: Time.zone.parse('2019/03/31 EAT'),
               coverage_start_date: Time.zone.parse('2019/01/01 EAT'),
               coverage_end_date: Time.zone.parse('2019/12/31 EAT'))
      end

      let(:unconfirmed_member) { create(:member, :unconfirmed) }
      let(:unenrolled_member) { create(:member) }
      let(:archived_date) { Time.zone.parse('2019/08/01 EAT') }
      let(:enrolled_archived_member) { create(:member, archived_at: archived_date, archived_reason: 'deceased') }
      let(:enrolled_date) { Time.zone.parse('2019/01/15 EAT') }
      let!(:household_enrollment_record) do
        create(:household_enrollment_record, household: enrolled_archived_member.household, enrollment_period: enrollment_period, enrolled_at: enrolled_date)
      end

      let!(:encounter1) { create(:encounter, member: unconfirmed_member) }
      let!(:encounter2) { create(:encounter, member: unenrolled_member) }
      let!(:encounter3) { create(:encounter, occurred_at: enrolled_date - 5.days, member: enrolled_archived_member) }
      let!(:encounter4) { create(:encounter, occurred_at: enrolled_date, member: enrolled_archived_member) }
      let!(:encounter5) { create(:encounter, occurred_at: enrolled_date + 1.day, member: enrolled_archived_member) }
      let!(:encounter6) { create(:encounter, occurred_at: archived_date - 1.day, member: enrolled_archived_member) }
      let!(:encounter7) { create(:encounter, occurred_at: archived_date, member: enrolled_archived_member) }
      let!(:encounter8) { create(:encounter, occurred_at: archived_date + 1.day, member: enrolled_archived_member) }

      it 'returns the encounters with inactive members at time of service' do
        expect(described_class.with_inactive_member_at_time_of_service).to match_array([encounter2, encounter3, encounter8])
      end
    end

    describe '.with_unlinked_inbound_referral' do
      let!(:encounter1) { create(:encounter, inbound_referral_date: nil, referral: nil) }
      let!(:encounter2) { create(:encounter, inbound_referral_date: 2.days.ago, referral: create(:referral)) }
      let!(:encounter3) { create(:encounter, inbound_referral_date: 2.days.ago, referral: nil) }

      it 'returns the encounters with unlinked inbound referrals' do
        expect(described_class.with_unlinked_inbound_referral).to match_array([encounter3])
      end
    end

    describe '.all_flagged and .not_flagged' do
      let(:enrollment_period) do
        create(:enrollment_period,
               start_date: Time.zone.parse('2018/10/01 EAT'),
               end_date: Time.zone.parse('2019/03/31 EAT'),
               coverage_start_date: Time.zone.parse('2019/01/01 EAT'),
               coverage_end_date: Time.zone.parse('2019/12/31 EAT'))
      end

      let(:unconfirmed_member) { create(:member, :unconfirmed) }
      let(:unenrolled_member) { create(:member) }
      let(:enrolled_member) { create(:member) }
      let(:enrolled_at) { Time.zone.parse('2019/01/15 EAT') }
      let!(:household_enrollment_record) do
        create(:household_enrollment_record, household: enrolled_member.household, enrollment_period: enrollment_period, enrolled_at: enrolled_at)
      end

      let!(:encounter_with_unconfirmed_member) { create(:encounter, member: unconfirmed_member) }
      let!(:encounter_with_inactive_member_of_time_of_service_1) { create(:encounter, member: unenrolled_member) }
      let!(:encounter_with_inactive_member_of_time_of_service_2) { create(:encounter, member: enrolled_member, occurred_at: enrolled_at - 1.day) }
      let!(:encounter_with_active_member_of_time_of_service) { create(:encounter, member: enrolled_member, occurred_at: enrolled_at + 1.day) }
      let!(:encounter_with_unlinked_inbound_referral) { create(:encounter, inbound_referral_date: 2.days.ago, referral: nil, member: enrolled_member, occurred_at: enrolled_at + 1.day) }

      it 'returns the encounters with any flag and no flags, respectively' do
        expect(described_class.all_flagged).to match_array([
                                                             encounter_with_unconfirmed_member,
                                                             encounter_with_inactive_member_of_time_of_service_1,
                                                             encounter_with_inactive_member_of_time_of_service_2,
                                                             encounter_with_unlinked_inbound_referral
                                                           ])
        expect(described_class.not_flagged).to match_array([encounter_with_active_member_of_time_of_service])
      end
    end

    describe '.latest' do
      let!(:duplicate_encounter) { create(:encounter, identification_event: create(:identification_event, dismissed: true)) }
      let!(:preadjudication_encounter) { create(:encounter, :prepared) }
      # chain size: 1
      let!(:encounter1) { create(:encounter) }
      # chain size: 2
      let!(:encounter2) { create(:encounter, :returned) }
      let!(:encounter3) { create(:encounter, :resubmission, revised_encounter: encounter2) }
      # chain size: 3
      let!(:encounter4) { create(:encounter, :returned) }
      let!(:encounter5) { create(:encounter, :resubmission, :returned, revised_encounter: encounter4) }
      let!(:encounter6) { create(:encounter, :resubmission, revised_encounter: encounter5) }

      it 'returns the last encounter in each chain' do
        expect(described_class.latest).to match_array([encounter1, encounter3, encounter6, preadjudication_encounter])
      end
    end

    describe '.initial_submissions' do
      let!(:duplicate_encounter) { create(:encounter, identification_event: create(:identification_event, dismissed: true)) }
      let!(:preadjudication_encounter) { create(:encounter, :prepared) }
      # chain size: 1
      let!(:encounter1) { create(:encounter) }
      # chain size: 2
      let!(:encounter2) { create(:encounter, :returned) }
      let!(:encounter3) { create(:encounter, :resubmission, revised_encounter: encounter2) }
      # chain size: 3
      let!(:encounter4) { create(:encounter, :returned) }
      let!(:encounter5) { create(:encounter, :resubmission, :returned, revised_encounter: encounter4) }
      let!(:encounter6) { create(:encounter, :resubmission, revised_encounter: encounter5) }

      it 'returns the last encounter in each chain' do
        expect(described_class.initial_submissions).to match_array([encounter1, encounter2, encounter4, preadjudication_encounter])
      end
    end

    describe '.load_costs' do
      # only the :with_specified_items trait in encounters factory supports creating encounter items that are stocked out, so we must use that one
      let!(:provider) { create(:provider) }
      let(:price_schedules) { create_list(:price_schedule, 5, provider: provider) }
      let!(:billables) { price_schedules.map(&:billable) }
      let!(:encounter1) { create(:encounter, provider: provider) }
      let!(:encounter2) { create(:encounter, :with_specified_items, billables: billables.sample(3), provider: provider) }
      let!(:encounter3) { create(:encounter, :with_specified_items, billables: billables.sample(3), stockout: true, provider: provider) }

      it 'calculates the correct price and reimbursal amount for all encounters and adds as additional columns' do
        costs = described_class.load_costs.pluck('id', 'encounter_costs.price', 'encounter_costs.reimbursal_amount')
        costs = costs.map { |id, price, reimbursal_amount| Hash[id, [price, reimbursal_amount]] }.inject(&:merge)

        expect(costs[encounter1.id]).to eq [encounter1.price, encounter1.reimbursal_amount]
        expect(costs[encounter2.id]).to eq [encounter2.price, encounter2.reimbursal_amount]
        expect(costs[encounter3.id]).to eq [encounter3.price, encounter3.reimbursal_amount]
      end
    end

    context 'reimbursed scopes' do
      let!(:reimbursed_encounter1) { create(:encounter) }
      let!(:reimbursed_encounter2) { create(:encounter) }
      let!(:reimbursement) { create(:reimbursement, encounter_count: 0, encounters: [reimbursed_encounter1, reimbursed_encounter2]) }
      let!(:not_reimbursed_encounter1) { create(:encounter) }
      let!(:not_reimbursed_encounter2) { create(:encounter) }

      describe '.reimbursed' do
        it 'returns reimbursed encounters' do
          expect(described_class.reimbursed).to match_array([reimbursed_encounter1, reimbursed_encounter2])
        end
      end

      describe '.not_reimbursed' do
        it 'returns encounters that have not been reimbursed' do
          expect(described_class.not_reimbursed).to match_array([not_reimbursed_encounter1, not_reimbursed_encounter2])
        end
      end
    end

    context 'claim pagination scopes' do
      let(:member1) { create(:member, membership_number: '000000') }
      let(:member2) { create(:member, membership_number: '000001') }
      let(:member3) { create(:member, membership_number: '222222') }
      let(:member4) { create(:member, membership_number: '333333') }
      let!(:encounter1) { create(:encounter, :approved, :with_items, price: 4000, claim_id: 'a106dd4d-ac9e-4607-ae47-9be2a084fdaf', submitted_at: Time.zone.parse('2017/03/15 00:00:00 EAT'), member: member1) }
      let!(:encounter2) { create(:encounter, :approved, :with_items, price: 1000, claim_id: '59e31e16-5815-4715-81a0-30621fdc853e', submitted_at: Time.zone.parse('2018/03/16 00:00:00 EAT'), member: member2) }
      let!(:encounter3) { create(:encounter, :rejected, :with_items, price: 2000, claim_id: '1a9cf33c-42ba-44d1-92a1-ad652e792606', submitted_at: Time.zone.parse('2018/03/16 00:00:00 EAT'), member: member3) }
      let!(:encounter4) { create(:encounter, :returned, :with_items, price: 2000, claim_id: 'f1aad306-3eb8-442b-af11-8f016d7d9097', submitted_at: Time.zone.parse('2019/01/01 00:00:00 EAT'), member: member4) }

      describe '.sort_by_field' do
        it 'returns encounters sorted by the specified field in the specified direction' do
          expect(described_class.sort_by_field('submitted_at', 'asc')).to eq [encounter1, encounter3, encounter2, encounter4]
          expect(described_class.sort_by_field('submitted_at', 'desc')).to eq [encounter4, encounter2, encounter3, encounter1]

          expect(described_class.sort_by_field('adjudication_state', 'asc')).to eq [encounter2, encounter1, encounter3, encounter4]
          expect(described_class.sort_by_field('adjudication_state', 'desc')).to eq [encounter4, encounter3, encounter1, encounter2]

          expect(described_class.load_costs.sort_by_field('reimbursal_amount', 'asc')).to eq [encounter2, encounter3, encounter4, encounter1]
          expect(described_class.load_costs.sort_by_field('reimbursal_amount', 'desc')).to eq [encounter1, encounter4, encounter3, encounter2]
        end
      end

      describe '.search_by_field' do
        it 'returns encounters that match the specified query for the specified field' do
          expect(described_class.search_by_field('claim_id', 'a106dd4d')).to match_array [encounter1]
          expect(described_class.search_by_field('claim_id', '1a9cf33c-42ba-44d1-92a1-ad652e792606')).to match_array [encounter3]

          expect(described_class.search_by_field('membership_number', '222222')).to match_array [encounter3]
          # Test shorter membership number substring. Note only five 0s, so it should match both member1 and member2
          expect(described_class.search_by_field('membership_number', '00000')).to match_array [encounter1, encounter2]
        end
      end

      describe '.starting_after' do
        it 'returns encounters after the given encounter by the specified field in the specified direction' do
          # use match_array for these comparisons since order is not guaranteed
          expect(described_class.starting_after(encounter3, 'submitted_at', 'asc')).to match_array [encounter2, encounter4]
          expect(described_class.starting_after(encounter3, 'submitted_at', 'desc')).to match_array [encounter1]

          expect(described_class.starting_after(encounter1, 'adjudication_state', 'asc')).to match_array [encounter3, encounter4]
          expect(described_class.starting_after(encounter1, 'adjudication_state', 'desc')).to match_array [encounter2]

          expect(described_class.load_costs.starting_after(encounter3, 'reimbursal_amount', 'asc')).to match_array [encounter4, encounter1]
          expect(described_class.load_costs.starting_after(encounter3, 'reimbursal_amount', 'desc')).to match_array [encounter2]
        end
      end

      describe '.ending_before' do
        it 'returns encounters before the given encounter by the specified field in the specified direction' do
          # use match_array for these comparisons since order is not guaranteed
          expect(described_class.ending_before(encounter3, 'submitted_at', 'asc')).to match_array [encounter1]
          expect(described_class.ending_before(encounter3, 'submitted_at', 'desc')).to match_array [encounter2, encounter4]

          expect(described_class.ending_before(encounter1, 'adjudication_state', 'asc')).to match_array [encounter2]
          expect(described_class.ending_before(encounter1, 'adjudication_state', 'desc')).to match_array [encounter3, encounter4]

          expect(described_class.load_costs.ending_before(encounter3, 'reimbursal_amount', 'asc')).to match_array [encounter2]
          expect(described_class.load_costs.ending_before(encounter3, 'reimbursal_amount', 'desc')).to match_array [encounter4, encounter1]
        end
      end
    end
  end

  describe 'self.to_claims' do
    # chain size: 1
    let!(:encounter1) { create(:encounter) }
    # chain size: 2
    let!(:encounter2) { create(:encounter, :returned) }
    let!(:encounter3) { create(:encounter, :resubmission, revised_encounter: encounter2) }
    # chain size: 3
    let!(:encounter4) { create(:encounter, :returned) }
    let!(:encounter5) { create(:encounter, :resubmission, :returned, revised_encounter: encounter4) }
    let!(:encounter6) { create(:encounter, :resubmission, revised_encounter: encounter5) }

    it 'returns the last encounter in each chain' do
      claims = described_class.to_claims([encounter1, encounter2, encounter3, encounter4, encounter5, encounter6])

      expect(claims.map(&:id)).to match_array([encounter1.claim_id, encounter3.claim_id, encounter6.claim_id])
      expect(claims.map(&:last_submitted_at)).to match_array([encounter1.submitted_at, encounter3.submitted_at, encounter6.submitted_at])
      expect(claims.map(&:encounters)).to match_array([[encounter1], [encounter2, encounter3], [encounter4, encounter5, encounter6]])
    end
  end

  describe 'Claim' do
    describe 'self.sort_by_field' do
      # chain size: 1
      let(:encounter1) { create(:encounter, claim_id: 'a106dd4d-ac9e-4607-ae47-9be2a084fdaf', submitted_at: 5.days.ago) }
      let!(:claim1) { Encounter::Claim.new(id: encounter1.claim_id, encounters: [encounter1]) }
      # chain size: 1
      let(:encounter2) { create(:encounter, claim_id: '59e31e16-5815-4715-81a0-30621fdc853e', submitted_at: 4.days.ago) }
      let!(:claim2) { Encounter::Claim.new(id: encounter2.claim_id, encounters: [encounter2]) }
      # chain size: 2
      let(:encounter3) { create(:encounter, :returned, claim_id: '1a9cf33c-42ba-44d1-92a1-ad652e792606', submitted_at: 6.days.ago) }
      let(:encounter4) { create(:encounter, :resubmission, revised_encounter: encounter3, submitted_at: 4.days.ago) }
      let!(:claim3) { Encounter::Claim.new(id: encounter3.claim_id, encounters: [encounter3, encounter4]) }
      # chain size: 3
      let(:encounter5) { create(:encounter, :returned, claim_id: 'f1aad306-3eb8-442b-af11-8f016d7d9097', submitted_at: 9.days.ago) }
      let(:encounter6) { create(:encounter, :resubmission, :returned, revised_encounter: encounter5, submitted_at: 8.days.ago) }
      let(:encounter7) { create(:encounter, :resubmission, revised_encounter: encounter6, submitted_at: 7.days.ago) }
      let!(:claim4) { Encounter::Claim.new(id: encounter5.claim_id, encounters: [encounter5, encounter6, encounter7]) }

      it 'correctly sorts claims by specified sort_field and sort_order' do
        claims = [claim1, claim2, claim3, claim4]
        expect(Encounter::Claim.sort_by_field(claims, 'submitted_at', 'asc')).to eq [claim4, claim1, claim2, claim3]
        expect(Encounter::Claim.sort_by_field(claims, 'submitted_at', 'desc')).to eq [claim3, claim2, claim1, claim4]

        expect(Encounter::Claim.sort_by_field(claims, 'claim_id', 'asc')).to eq [claim3, claim2, claim1, claim4]
        expect(Encounter::Claim.sort_by_field(claims, 'claim_id', 'desc')).to eq [claim4, claim1, claim2, claim3]
      end
    end
  end

  describe '#reimbursal_amount' do
    context 'when there are no encounter items' do
      subject { create(:encounter) }

      it 'returns 0' do
        expect(subject.reimbursal_amount).to eq 0
      end
    end

    context 'when there is only one encounter item' do
      subject { create(:encounter, custom_reimbursal_amount: 5000) }
      let(:price_schedule) { create(:price_schedule, provider: subject.provider) }

      before do
        create(:encounter_item, quantity: 1, price_schedule: price_schedule, encounter: subject)
      end

      it 'returns the custom reimbursal amount' do
        expect(subject.reload.reimbursal_amount).to eq 5000
      end
    end
  end

  describe '#price' do
    subject { create(:encounter) }

    context 'when there are no encounter items' do
      it 'returns 0' do
        expect(subject.price).to eq 0
      end
    end

    context 'when there is only one encounter item' do
      let(:price_schedule) { create(:price_schedule, provider: subject.provider) }

      before do
        create(:encounter_item, quantity: 1, price_schedule: price_schedule, encounter: subject)
      end

      it 'returns the price of the billable on the item' do
        expect(subject.reload.price).to eq price_schedule.price
      end
    end

    context 'when there is only one encounter item with a > 1 quantity' do
      let(:price_schedule) { create(:price_schedule, provider: subject.provider) }

      before do
        create(:encounter_item, quantity: 5, price_schedule: price_schedule, encounter: subject)
      end

      it 'returns the quantity times the price of the billable on the item' do
        expect(subject.reload.price).to eq (5 * price_schedule.price)
      end
    end

    context 'when there is a stockout' do
      let(:price_schedule1) { create(:price_schedule, provider: subject.provider) }
      let(:price_schedule2) { create(:price_schedule, provider: subject.provider) }

      before do
        create(:encounter_item, quantity: 1, price_schedule: price_schedule1, encounter: subject)
        create(:encounter_item, quantity: 1, price_schedule: price_schedule2, encounter: subject, stockout: true)
      end

      it 'returns the total price of the billables' do
        expect(subject.reload.price).to eq (price_schedule1.price)
      end
    end

    context 'when there are multiple encounter items' do
      let(:price_schedule1) { create(:price_schedule, provider: subject.provider) }
      let(:price_schedule2) { create(:price_schedule, provider: subject.provider) }

      before do
        create(:encounter_item, quantity: 1, price_schedule: price_schedule1, encounter: subject)
        create(:encounter_item, quantity: 1, price_schedule: price_schedule2, encounter: subject)
      end

      it 'returns the total price of the billables' do
        expect(subject.reload.price).to eq (price_schedule1.price + price_schedule2.price)
      end
    end

    context 'when there are multiple encounter items with > 1 quantities' do
      let(:price_schedule1) { create(:price_schedule, provider: subject.provider) }
      let(:price_schedule2) { create(:price_schedule, provider: subject.provider) }

      before do
        create(:encounter_item, quantity: 2, price_schedule: price_schedule1, encounter: subject)
        create(:encounter_item, quantity: 4, price_schedule: price_schedule2, encounter: subject)
      end

      it 'returns the quantity times the price of the billable on each item' do
        expect(subject.reload.price).to eq (2 * price_schedule1.price + 4 * price_schedule2.price)
      end
    end
  end

  describe '#price_schedules_with_previous' do
    subject { create(:encounter) }

    context 'when there are no encounter items' do
      it 'returns an empty list' do
        expect(subject.price_schedules_with_previous).to eq []
      end
    end

    context 'when there are encounter items without new price schedules issued' do
      let(:price_schedule1) { create(:price_schedule, provider: subject.provider) }
      let(:price_schedule2) { create(:price_schedule, provider: subject.provider) }

      before do
        create(:encounter_item, price_schedule: price_schedule1, encounter: subject)
        create(:encounter_item, price_schedule: price_schedule2, encounter: subject)
      end

      it 'returns a list of all price schedules associated with the encounter items' do
        expect(subject.reload.price_schedules_with_previous).to match_array [price_schedule1, price_schedule2]
      end
    end

    context 'when there are encounter items with new price schedules issued' do
      let(:price_schedule_1) { create(:price_schedule, :with_previous, provider: subject.provider) }
      let(:price_schedule_2) { create(:price_schedule, :with_previous, provider: subject.provider) }
      let(:price_schedule_3) { create(:price_schedule, provider: subject.provider) }

      before do
        create(:encounter_item, price_schedule_issued: true, price_schedule: price_schedule_1, encounter: subject)
        create(:encounter_item, price_schedule_issued: false, price_schedule: price_schedule_2, encounter: subject)
        create(:encounter_item, price_schedule: price_schedule_3, encounter: subject)
      end

      it 'returns a list of all price schedules and previous price schedules for encounter items that issued new price schedules' do
        expect(subject.reload.price_schedules_with_previous).to match_array [price_schedule_1, price_schedule_1.previous_price_schedule, price_schedule_2, price_schedule_3]
      end
    end
  end

  describe '#get_total_by_accounting_group' do
    let(:billable_drug) { create(:billable, accounting_group: "drug_and_supply") }
    let(:billable_card) { create(:billable, accounting_group: "card_and_consultation") }
    let(:billable_capitation) { create(:billable, accounting_group: "capitation") }

    # drug item with stockout
    let(:price_schedule1) { create(:price_schedule, price: 5, billable: billable_drug) }
    let(:encounter_item1) { create(:encounter_item, price_schedule: price_schedule1, quantity: 2, stockout: true) }

    # drug total price of 10
    let(:price_schedule2) { create(:price_schedule, price: 10, billable: billable_drug) }
    let(:encounter_item2) { create(:encounter_item, price_schedule: price_schedule2, quantity: 1, stockout: false) }

    # drug total price of 6
    let(:price_schedule3) { create(:price_schedule, price: 2, billable: billable_drug) }
    let(:encounter_item3) { create(:encounter_item, price_schedule: price_schedule3, quantity: 3, stockout: false) }

    # card total price of 5
    let(:price_schedule4) { create(:price_schedule, price: 5, billable: billable_card) }
    let(:encounter_item4) { create(:encounter_item, price_schedule: price_schedule4, quantity: 1, stockout: false) }

    # capitation total price of 15
    let(:price_schedule5) { create(:price_schedule, price: 15, billable: billable_capitation) }
    let(:encounter_item5) { create(:encounter_item, price_schedule: price_schedule5, quantity: 1, stockout: false) }

    let(:encounter) { create(:encounter, encounter_items: [encounter_item1, encounter_item2, encounter_item3, encounter_item4, encounter_item5]) }

    it 'returns hash with accounting category proper totals' do
      accounting_groups = ["drug_and_supply", "card_and_consultation", "capitation", "other_services"]
      expected = {
        "drug_and_supply" => 16,
        "card_and_consultation" => 5,
        "capitation" => 15,
        "other_services" => 0,
      }

      expect(encounter.get_total_by_accounting_group(accounting_groups)).to eq expected
    end
  end

  specify 'started?' do
    expect(build(:encounter, submission_state: 'started').started?).to be true
    expect(build(:encounter, submission_state: 'prepared').started?).to be false
  end

  specify 'prepared?' do
    expect(build(:encounter, submission_state: 'prepared').prepared?).to be true
    expect(build(:encounter, submission_state: 'submitted').prepared?).to be false
  end

  specify 'submitted?' do
    expect(build(:encounter, submission_state: 'submitted').submitted?).to be true
    expect(build(:encounter, submission_state: 'needs_revision').submitted?).to be false
  end

  specify 'needs_revision?' do
    expect(build(:encounter, submission_state: 'needs_revision').needs_revision?).to be true
    expect(build(:encounter, submission_state: 'started').needs_revision?).to be false
  end

  specify 'pending?' do
    expect(build(:encounter, adjudication_state: 'pending').pending?).to be true
    expect(build(:encounter, adjudication_state: 'approved').pending?).to be false
  end

  specify 'returned?' do
    expect(build(:encounter, adjudication_state: 'returned').returned?).to be true
    expect(build(:encounter, adjudication_state: 'pending').returned?).to be false
  end

  specify 'rejected?' do
    expect(build(:encounter, adjudication_state: 'rejected').rejected?).to be true
    expect(build(:encounter, adjudication_state: 'pending').rejected?).to be false
  end

  specify 'approved?' do
    expect(build(:encounter, adjudication_state: 'approved').approved?).to be true
    expect(build(:encounter, adjudication_state: 'pending').approved?).to be false
  end

  specify 'revised?' do
    expect(build(:encounter, adjudication_state: 'revised').revised?).to be true
    expect(build(:encounter, adjudication_state: 'pending').revised?).to be false
  end

  specify 'resubmitted?' do
    expect(build(:encounter, resubmitted_encounter: build(:encounter)).resubmitted?).to be true
    expect(build(:encounter).resubmitted?).to be false
  end

  specify 'reimbursed?' do
    expect(build(:encounter, reimbursement: build(:reimbursement)).reimbursed?).to be true
    expect(build(:encounter).reimbursed?).to be false
  end
end
