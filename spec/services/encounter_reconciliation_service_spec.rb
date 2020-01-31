require 'rails_helper'

RSpec.describe EncounterReconciliationService, :use_database_rewinder do
  membership_number = '222222'.freeze

  let(:household) { create(:household) }
  let!(:member_with_household) { create(:member, household: household, membership_number: membership_number) }
  let!(:member_manual) { create(:member, household: nil, membership_number: membership_number) }
  let!(:member_mismatch_mem_number) { create(:member, membership_number: '333333') }
  let!(:provider1) { create(:provider) }
  let!(:provider2) { create(:provider) }
  let!(:identification_user) { create(:user, :identification, provider: provider1) }
  let!(:claims_preparer_user) { create(:user, :submission, provider: provider1) }
  let!(:occurred_at1) { Time.zone.local(2019, 1, 1) }
  let!(:occurred_at2) { Time.zone.local(2019, 1, 2) }

  describe 'reconciling claims and members' do
    context 'only 1 encounter' do
      let!(:encounter1) { create(:encounter, :started, member: member_with_household, provider: provider1, occurred_at: occurred_at1, user: identification_user) }

      it 'has no effect' do
        EncounterReconciliationService.new.reconcile!(encounter1)
        encounter1.reload
        member_with_household.reload

        expect(encounter1.identification_event.dismissed?).to be false
        expect(encounter1.member).to eql(member_with_household)
        expect(member_with_household.duplicate?).to be false
      end
    end

    context 'with mismatch membership number' do
      let!(:encounter1) { create(:encounter, :started, member: member_with_household, provider: provider1, occurred_at: occurred_at1, user: identification_user) }
      let!(:encounter2) { create(:encounter, :prepared, member: member_mismatch_mem_number, provider: provider1, occurred_at: occurred_at1, user: claims_preparer_user) }

      it 'has no effect' do
        EncounterReconciliationService.new.reconcile!(encounter1)
        encounter1.reload
        encounter2.reload
        member_with_household.reload
        member_mismatch_mem_number.reload

        expect(encounter1.identification_event.dismissed?).to be false
        expect(encounter1.member).to eql(member_with_household)
        expect(encounter2.identification_event.dismissed?).to be false
        expect(encounter2.member).to eql(member_mismatch_mem_number)
        expect(member_with_household.duplicate?).to be false
        expect(member_mismatch_mem_number.duplicate?).to be false
      end
    end

    context 'with mismatch provider' do
      let!(:encounter1) { create(:encounter, :started, member: member_with_household, provider: provider1, occurred_at: occurred_at1, user: identification_user) }
      let!(:encounter2) { create(:encounter, :prepared, member: member_with_household, provider: provider2, occurred_at: occurred_at1, user: claims_preparer_user) }

      it 'has no effect' do
        EncounterReconciliationService.new.reconcile!(encounter1)
        encounter1.reload
        encounter2.reload
        member_with_household.reload

        expect(encounter1.identification_event.dismissed?).to be false
        expect(encounter1.member).to eql(member_with_household)
        expect(encounter2.identification_event.dismissed?).to be false
        expect(encounter2.member).to eql(member_with_household)
        expect(member_with_household.duplicate?).to be false
      end
    end

    context 'with mismatch date of service' do
      let!(:encounter1) { create(:encounter, :started, member: member_with_household, provider: provider1, occurred_at: occurred_at1, user: identification_user) }
      let!(:encounter2) { create(:encounter, :prepared, member: member_with_household, provider: provider1, occurred_at: occurred_at2, user: claims_preparer_user) }

      it 'has no effect' do
        EncounterReconciliationService.new.reconcile!(encounter1)
        encounter1.reload
        encounter2.reload
        member_with_household.reload

        expect(encounter1.identification_event.dismissed?).to be false
        expect(encounter1.member).to eql(member_with_household)
        expect(encounter2.identification_event.dismissed?).to be false
        expect(encounter2.member).to eql(member_with_household)
        expect(member_with_household.duplicate?).to be false
      end
    end

    context 'with mismatch date of service by one hour' do
      beginning_of_day = Time.zone.now.beginning_of_day
      let!(:encounter1) { create(:encounter, :started, member: member_with_household, provider: provider1, occurred_at: beginning_of_day, user: identification_user) }
      let!(:encounter2) { create(:encounter, :prepared, member: member_with_household, provider: provider1, occurred_at: beginning_of_day - 1.hours, user: claims_preparer_user) }

      it 'has no effect' do
        EncounterReconciliationService.new.reconcile!(encounter1)
        encounter1.reload
        encounter2.reload
        member_with_household.reload

        expect(encounter1.identification_event.dismissed?).to be false
        expect(encounter1.member).to eql(member_with_household)
        expect(encounter2.identification_event.dismissed?).to be false
        expect(encounter2.member).to eql(member_with_household)
        expect(member_with_household.duplicate?).to be false
      end
    end

    context 'with two matching started encounters and the same member' do
      let!(:encounter1) { create(:encounter, :started, member: member_with_household, provider: provider1, occurred_at: occurred_at1, user: identification_user) }
      let!(:encounter2) { create(:encounter, :started, member: member_with_household, provider: provider1, occurred_at: occurred_at1, user: identification_user) }

      it 'merges encounter, does not affect member' do
        EncounterReconciliationService.new.reconcile!(encounter1)
        encounter1.reload
        encounter2.reload
        member_with_household.reload

        # We don't know which encounter will be primary, so we XOR to ensure that
        # exaclty one is dismissed and one is not
        expect(encounter1.identification_event.dismissed? ^ encounter2.identification_event.dismissed?).to be true
        expect(encounter1.member).to eql(member_with_household)
        expect(encounter2.member).to eql(member_with_household)
        expect(member_with_household.duplicate?).to be false
      end
    end

    context 'with two started encounters, different but same day date of service, and the same member' do
      beginning_of_day = Time.zone.now.beginning_of_day
      let!(:encounter1) { create(:encounter, :started, member: member_with_household, provider: provider1, occurred_at: beginning_of_day, user: identification_user) }
      let!(:encounter2) { create(:encounter, :started, member: member_with_household, provider: provider1, occurred_at: beginning_of_day + 23.hour, user: identification_user) }

      it 'merges encounter, does not affect member' do
        EncounterReconciliationService.new.reconcile!(encounter1)
        encounter1.reload
        encounter2.reload
        member_with_household.reload

        # We don't know which encounter will be primary, so we XOR to ensure that
        # exaclty one is dismissed and one is not
        expect(encounter1.identification_event.dismissed? ^ encounter2.identification_event.dismissed?).to be true
        expect(encounter1.member).to eql(member_with_household)
        expect(encounter2.member).to eql(member_with_household)
        expect(member_with_household.duplicate?).to be false
      end
    end

    context 'with two matching started encounters and a manual member' do
      let!(:encounter1) { create(:encounter, :started, member: member_with_household, provider: provider1, occurred_at: occurred_at1, user: identification_user) }
      let!(:encounter2) { create(:encounter, :started, member: member_manual, provider: provider1, occurred_at: occurred_at1, user: identification_user) }

      it 'merges encounter, archives manual member' do
        EncounterReconciliationService.new.reconcile!(encounter1)
        encounter1.reload
        encounter2.reload
        member_with_household.reload
        member_manual.reload

        # We don't know which encounter will be primary, so we XOR to ensure that
        # exaclty one is dismissed and one is not
        expect(encounter1.identification_event.dismissed? ^ encounter2.identification_event.dismissed?).to be true
        expect(member_with_household.duplicate?).to be false
        expect(member_manual.duplicate?).to be true
        expect(member_manual.original_member).to eql(member_with_household)
      end
    end

    context 'with two matching started encounters and a different enrolled member' do
      let!(:other_enrolled_member) { create(:member, household: household, membership_number: membership_number) }
      let!(:encounter1) { create(:encounter, :started, member: member_with_household, provider: provider1, occurred_at: occurred_at1, user: identification_user) }
      let!(:encounter2) { create(:encounter, :started, member: other_enrolled_member, provider: provider1, occurred_at: occurred_at1, user: identification_user) }

      it 'has no effect' do
        EncounterReconciliationService.new.reconcile!(encounter1)
        encounter1.reload
        encounter2.reload
        member_with_household.reload
        other_enrolled_member.reload

        expect(encounter1.identification_event.dismissed?).to be false
        expect(encounter1.member).to eql(member_with_household)
        expect(encounter2.identification_event.dismissed?).to be false
        expect(encounter2.member).to eql(other_enrolled_member)
        expect(member_with_household.duplicate?).to be false
        expect(other_enrolled_member.duplicate?).to be false
      end
    end

    context 'with a matching started encounter and prepared encounter and the same member' do
      let!(:encounter1) { create(:encounter, :started, member: member_with_household, provider: provider1, occurred_at: occurred_at1, user: identification_user) }
      let!(:encounter2) { create(:encounter, :prepared, member: member_with_household, provider: provider1, occurred_at: occurred_at1, user: claims_preparer_user) }

      it 'merges started encounter, does not affect member' do
        EncounterReconciliationService.new.reconcile!(encounter1)
        encounter1.reload
        encounter2.reload
        member_with_household.reload

        expect(encounter1.identification_event.dismissed?).to be true
        expect(encounter1.member).to eql(member_with_household)
        expect(encounter2.identification_event.dismissed?).to be false
        expect(encounter2.member).to eql(member_with_household)
        expect(member_with_household.duplicate?).to be false
      end
    end

    context 'with a matching started encounter and prepared encounter and a manual member' do
      let!(:encounter1) { create(:encounter, :started, member: member_with_household, provider: provider1, occurred_at: occurred_at1, user: identification_user) }
      let!(:encounter2) { create(:encounter, :prepared, member: member_manual, provider: provider1, occurred_at: occurred_at1, user: claims_preparer_user) }

      it 'merges started encounter, archives member' do
        EncounterReconciliationService.new.reconcile!(encounter1)
        encounter1.reload
        encounter2.reload
        member_with_household.reload
        member_manual.reload

        expect(encounter1.identification_event.dismissed?).to be true
        expect(encounter1.member).to eql(member_with_household)
        expect(encounter2.identification_event.dismissed?).to be false
        expect(encounter2.member).to eql(member_with_household)
        expect(member_with_household.duplicate?).to be false
        expect(member_manual.duplicate?).to be true
        expect(member_manual.original_member).to eql(member_with_household)
      end
    end

    context 'with two matching prepared encounters and a started encounter' do
      let!(:encounter1) { create(:encounter, :prepared, member: member_manual, provider: provider1, occurred_at: occurred_at1, user: claims_preparer_user) }
      let!(:encounter2) { create(:encounter, :prepared, member: member_with_household, provider: provider1, occurred_at: occurred_at1, user: claims_preparer_user) }
      let!(:encounter3) { create(:encounter, :started, member: member_with_household, provider: provider1, occurred_at: occurred_at1, user: identification_user) }

      it 'has no effect' do
        EncounterReconciliationService.new.reconcile!(encounter1)
        encounter1.reload
        encounter2.reload
        encounter3.reload
        member_with_household.reload
        member_manual.reload

        expect(encounter1.identification_event.dismissed?).to be false
        expect(encounter1.member).to eql(member_manual)
        expect(encounter2.identification_event.dismissed?).to be false
        expect(encounter2.member).to eql(member_with_household)
        expect(encounter3.identification_event.dismissed?).to be false
        expect(encounter3.member).to eql(member_with_household)
        expect(member_with_household.duplicate?).to be false
        expect(member_manual.duplicate?).to be false
      end
    end

    context 'with two matching started encounters and a prepared encounter' do
      let!(:encounter1) { create(:encounter, :prepared, member: member_manual, provider: provider1, occurred_at: occurred_at1, user: claims_preparer_user) }
      let!(:encounter2) { create(:encounter, :started, member: member_with_household, provider: provider1, occurred_at: occurred_at1, user: identification_user) }
      let!(:encounter3) { create(:encounter, :started, member: member_with_household, provider: provider1, occurred_at: occurred_at1, user: identification_user) }

      it 'merges started encounters, archives member' do
        EncounterReconciliationService.new.reconcile!(encounter1)
        encounter1.reload
        encounter2.reload
        encounter3.reload
        member_with_household.reload
        member_manual.reload

        expect(encounter1.identification_event.dismissed?).to be false
        expect(encounter1.member).to eql(member_with_household)
        expect(encounter2.identification_event.dismissed?).to be true
        expect(encounter2.member).to eql(member_with_household)
        expect(encounter3.identification_event.dismissed?).to be true
        expect(encounter3.member).to eql(member_with_household)
        expect(member_with_household.duplicate?).to be false
        expect(member_manual.duplicate?).to be true
        expect(member_manual.original_member).to eql(member_with_household)
      end
    end

    context 'with a matching started encounter and prepared encounter and a manual member, and is run twice' do
      let!(:encounter1) { create(:encounter, :started, member: member_with_household, provider: provider1, occurred_at: occurred_at1, user: identification_user) }
      let!(:encounter2) { create(:encounter, :prepared, member: member_manual, provider: provider1, occurred_at: occurred_at1, user: claims_preparer_user) }

      it 'merges started encounter, archives member' do
        EncounterReconciliationService.new.reconcile!(encounter1)
        EncounterReconciliationService.new.reconcile!(encounter2)
        encounter1.reload
        encounter2.reload
        member_with_household.reload
        member_manual.reload

        expect(encounter1.identification_event.dismissed?).to be true
        expect(encounter1.member).to eql(member_with_household)
        expect(encounter2.identification_event.dismissed?).to be false
        expect(encounter2.member).to eql(member_with_household)
        expect(member_with_household.duplicate?).to be false
        expect(member_manual.duplicate?).to be true
        expect(member_manual.original_member).to eql(member_with_household)
      end
    end

    context 'with reimbursed claim' do
      let!(:reimbursement) { create(:reimbursement) }
      let!(:encounter1) { create(:encounter, :started, member: member_with_household, provider: provider1, occurred_at: occurred_at1, user: identification_user) }
      let!(:encounter2) { create(:encounter, reimbursement: reimbursement, member: member_with_household, provider: provider1, occurred_at: occurred_at1, user: claims_preparer_user) }

      it 'has no effect' do
        EncounterReconciliationService.new.reconcile!(encounter1)
        encounter1.reload
        encounter2.reload
        member_with_household.reload
        member_mismatch_mem_number.reload

        expect(encounter1.identification_event.dismissed?).to be false
        expect(encounter1.member).to eql(member_with_household)
        expect(encounter2.identification_event.dismissed?).to be false
        expect(encounter2.member).to eql(member_with_household)
        expect(member_with_household.duplicate?).to be false
      end
    end

    context 'with approved claim' do
      let!(:encounter1) { create(:encounter, :started, member: member_with_household, provider: provider1, occurred_at: occurred_at1, user: identification_user) }
      let!(:encounter2) { create(:encounter, :approved, member: member_with_household, provider: provider1, occurred_at: occurred_at1, user: claims_preparer_user) }

      it 'has no effect' do
        EncounterReconciliationService.new.reconcile!(encounter1)
        encounter1.reload
        encounter2.reload
        member_with_household.reload
        member_mismatch_mem_number.reload

        expect(encounter1.identification_event.dismissed?).to be false
        expect(encounter1.member).to eql(member_with_household)
        expect(encounter2.identification_event.dismissed?).to be false
        expect(encounter2.member).to eql(member_with_household)
        expect(member_with_household.duplicate?).to be false
      end
    end

    context 'with returned claim that becomes revised' do
      let!(:encounter1) { create(:encounter, :started, member: member_with_household, provider: provider1, occurred_at: occurred_at1, user: identification_user) }
      let!(:encounter2) { create(:encounter, :returned, member: member_with_household, provider: provider1, occurred_at: occurred_at1, user: claims_preparer_user) }

      it 'has no effect before revision' do
        EncounterReconciliationService.new.reconcile!(encounter1)
        encounter1.reload
        encounter2.reload
        member_with_household.reload
        member_mismatch_mem_number.reload

        expect(encounter1.identification_event.dismissed?).to be false
        expect(encounter1.member).to eql(member_with_household)
        expect(encounter2.identification_event.dismissed?).to be false
        expect(encounter2.member).to eql(member_with_household)
        expect(member_with_household.duplicate?).to be false
      end

      it 'markes the started claim as a dupliate after the returned claims is revised' do
        encounter3 = create(:encounter, :pending, member: member_with_household, provider: provider1, occurred_at: occurred_at1, user: claims_preparer_user)
        encounter2.revised_encounter_id = encounter3
        encounter2.save!
        EncounterReconciliationService.new.reconcile!(encounter3)
        encounter1.reload
        encounter2.reload
        member_with_household.reload
        member_mismatch_mem_number.reload

        expect(encounter1.identification_event.dismissed?).to be true
        expect(encounter1.member).to eql(member_with_household)
        expect(encounter2.identification_event.dismissed?).to be false
        expect(encounter2.member).to eql(member_with_household)
        expect(encounter3.member).to eql(member_with_household)
        expect(member_with_household.duplicate?).to be false
      end
    end

    context 'with dismissed claim' do
      let!(:identification_event) { create(:identification_event, dismissed: true) }
      let!(:encounter1) { create(:encounter, :started, member: member_with_household, provider: provider1, occurred_at: occurred_at1, user: identification_user) }
      let!(:encounter2) { create(:encounter, identification_event: identification_event, member: member_with_household, provider: provider1, occurred_at: occurred_at1, user: claims_preparer_user) }

      it 'has no effect' do
        EncounterReconciliationService.new.reconcile!(encounter1)
        encounter1.reload
        encounter2.reload
        member_with_household.reload
        member_mismatch_mem_number.reload

        expect(encounter1.identification_event.dismissed?).to be false
        expect(encounter1.member).to eql(member_with_household)
        expect(encounter2.identification_event.dismissed?).to be true
        expect(encounter2.member).to eql(member_with_household)
        expect(member_with_household.duplicate?).to be false
      end
    end
  end
end
