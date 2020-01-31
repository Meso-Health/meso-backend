require 'rails_helper'

RSpec.describe ReferralMatchingService do
  let!(:date1) { Time.zone.local(2019, 7, 2)}
  let!(:date2) { Time.zone.local(2019, 7, 13)}
  let!(:receiving_facility) { create(:provider) }
  let!(:member) { create(:member) }

  describe 'match_from_inbound_referral_date' do
    context 'referral exists not linked' do
      let!(:encounter_with_referral_outcome) { create(:encounter, :approved, patient_outcome: 'referred', member_id: member.id) }
      let!(:referral) { create(:referral, encounter: encounter_with_referral_outcome, reason: 'drug_stockout', receiving_facility: receiving_facility.name) }
      let!(:encounter_with_inbound_referral) {
        create(:encounter, :with_inbound_referral_date, member_id: member.id, inbound_referral_date: referral.date)
      }

      it 'sets referral_id on encounter with inbound_referral_date that matches referral.date' do
        expect(encounter_with_inbound_referral.referral_id).to be_nil
        ReferralMatchingService.new.match_from_inbound_referral_date!(encounter_with_inbound_referral)
        encounter_with_inbound_referral.reload
        expect(encounter_with_inbound_referral.referral_id).to eq referral.id
      end
    end

    context 'referral linked to past submission' do
      let!(:encounter_with_referral_outcome) { create(:encounter, :approved, patient_outcome: 'referred', member_id: member.id) }
      let!(:referral) { create(:referral, encounter: encounter_with_referral_outcome, reason: 'drug_stockout', receiving_facility: receiving_facility.name) }

      let!(:original_encounter) { create(:encounter, :returned, :with_inbound_referral_date, referral_id: referral.id, member_id: member.id, inbound_referral_date: referral.date) }
      let!(:resubmitted_encounter) { create(:encounter, :resubmission, :approved, member_id: member.id, revised_encounter: original_encounter, inbound_referral_date: referral.date) }

      before do
        ReferralMatchingService.new.match_from_inbound_referral_date!(resubmitted_encounter)
      end
      
      it 'unlinks past submission' do
        original_encounter.reload
        expect(original_encounter.referral_id).to be_nil
      end

      it 'links new submission' do
        resubmitted_encounter.reload
        expect(resubmitted_encounter.referral_id).to eq referral.id
      end
    end

    context 'referral does not exist' do
      let!(:encounter) { create(:encounter, :returned, :with_inbound_referral_date, member_id: member.id, inbound_referral_date: date1) }

      before do
        ReferralMatchingService.new.match_from_inbound_referral_date!(encounter)
      end

      it 'does not make a link' do
        encounter.reload
        expect(encounter.referral_id).to be_nil
      end
    end
  end

  describe 'match_from_referral' do
    context 'matching encounter does not exist' do
      let!(:encounter_with_referral_outcome) { create(:encounter, :approved, patient_outcome: 'referred', member_id: member.id) }
      let!(:referral) { create(:referral, encounter: encounter_with_referral_outcome, reason: 'drug_stockout', receiving_facility: receiving_facility.name) }

      before do
        ReferralMatchingService.new.match_from_referral!(referral)
      end

      it 'does not make a link' do
        matching_encounter = Encounter.where(referral_id: referral.id).first
        expect(matching_encounter).to be_nil
      end
    end

    context 'matching multiple encounters from different claims' do
      let!(:encounter_with_referral_outcome) { create(:encounter, :approved, patient_outcome: 'referred', member_id: member.id) }
      let!(:referral) { create(:referral, encounter: encounter_with_referral_outcome, reason: 'drug_stockout', receiving_facility: receiving_facility.name) }
      let!(:encounter1) { create(:encounter, :returned, :with_inbound_referral_date, member_id: member.id, inbound_referral_date: referral.date, submitted_at: date1) }
      let!(:encounter2) { create(:encounter, :returned, :with_inbound_referral_date, member_id: member.id, inbound_referral_date: referral.date, submitted_at: date2) }

      before do
        ReferralMatchingService.new.match_from_referral!(referral)
      end

      it 'matches first encounter submitted' do
        matching_encounter = Encounter.where(referral_id: referral.id)
        expect(matching_encounter.length). to eq 1
        expect(matching_encounter.first.id).to eq encounter1.id
        expect(matching_encounter.first.id).to_not eq encounter2.id
      end
    end

    context 'update link for match encounter for referral resubmission' do
      let!(:original_encounter_with_referral_outcome) { create(:encounter, :returned, patient_outcome: 'referred', member_id: member.id) }
      let!(:original_referral) { create(:referral, date: date1, encounter: original_encounter_with_referral_outcome, reason: 'drug_stockout', receiving_facility: receiving_facility.name) }
      let!(:resubmitted_encounter_with_referral_outcome) { create(:encounter, :resubmission, :approved, patient_outcome: 'referred', member_id: member.id, revised_encounter: original_encounter_with_referral_outcome) }
      let!(:resubmitted_referral) { create(:referral, date: date1, encounter: resubmitted_encounter_with_referral_outcome, reason: 'drug_stockout', receiving_facility: receiving_facility.name) }

      let!(:matching_encounter) { create(:encounter, :returned, :with_inbound_referral_date, referral_id: original_referral.id, member_id: member.id, inbound_referral_date: date1) }

      before do
        ReferralMatchingService.new.match_from_referral!(resubmitted_referral)
      end

      it 'unlinks past referral & links new referral' do
        matching_encounter.reload
        expect(matching_encounter.referral_id).to_not eq original_referral.id
        expect(matching_encounter.referral_id).to eq resubmitted_referral.id
      end
    end

    context 'encounter already has referral from another claim' do
      let!(:original_encounter_with_referral_outcome) { create(:encounter, :approved, patient_outcome: 'referred', member_id: member.id) }
      let!(:original_referral) { create(:referral, date: date1, encounter: original_encounter_with_referral_outcome, reason: 'drug_stockout', receiving_facility: receiving_facility.name) }
      let!(:second_encounter_with_referral_outcome) { create(:encounter, :approved, patient_outcome: 'referred', member_id: member.id) }
      let!(:second_referral) { create(:referral, date: date1, encounter: second_encounter_with_referral_outcome, reason: 'drug_stockout', receiving_facility: receiving_facility.name) }

      let!(:matching_encounter) { create(:encounter, :returned, :with_inbound_referral_date, referral_id: original_referral.id, member_id: member.id, inbound_referral_date: date1) }

      before do
        ReferralMatchingService.new.match_from_referral!(second_referral)
      end

      it 'remains linked to original referral' do
        matching_encounter.reload
        expect(matching_encounter.referral_id).to eq original_referral.id
        expect(matching_encounter.referral_id).to_not eq second_referral.id
      end
    end
  end
end
