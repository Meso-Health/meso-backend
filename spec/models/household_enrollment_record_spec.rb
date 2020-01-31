require 'rails_helper'

RSpec.describe HouseholdEnrollmentRecord, type: :model do
  describe '#total_payments' do
    context 'when there are payments' do
      let!(:household_enrollment_record) { create(:household_enrollment_record) }
      let!(:membership_payment) { create(:membership_payment,
        registration_fee: 1000,
        household_enrollment_record: household_enrollment_record
      )}

      let!(:membership_payment2) { create(:membership_payment,
        annual_contribution_fee: 2500,
        household_enrollment_record: household_enrollment_record
      )}

      let!(:membership_payment3) { create(:membership_payment,
        annual_contribution_fee: 2500,
        other_fee: 20000,
        penalty_fee: 30,
        household_enrollment_record: household_enrollment_record
      )}

      let!(:membership_payment4) { create(:membership_payment,
        card_replacement_fee: 500,
        household_enrollment_record: household_enrollment_record
      )}

      it 'should return the right number' do
        expect(household_enrollment_record.total_payments).to eq 265.30
      end
    end

    context 'when there are no payments' do
      let!(:household_enrollment_record) { create(:household_enrollment_record) }

      it 'should return zero' do
        expect(household_enrollment_record.total_payments).to eq 0
      end
    end
  end

  context '#sum_fee_of_type' do
    context 'when there are payments' do
      let!(:household_enrollment_record) { create(:household_enrollment_record) }
      let!(:membership_payment) { create(:membership_payment,
        registration_fee: 1000,
        household_enrollment_record: household_enrollment_record
      )}

      let!(:membership_payment2) { create(:membership_payment,
        annual_contribution_fee: 2500,
        household_enrollment_record: household_enrollment_record
      )}

      let!(:membership_payment3) { create(:membership_payment,
        annual_contribution_fee: 500,
        other_fee: 20000,
        penalty_fee: 30,
        household_enrollment_record: household_enrollment_record
      )}

      let!(:membership_payment4) { create(:membership_payment,
        card_replacement_fee: 500,
        qualifying_beneficiaries_fee: 50,
        household_enrollment_record: household_enrollment_record
      )}

      it 'should return the right numbers' do
        expect(household_enrollment_record.sum_fee_of_type(:registration_fee)).to be 10.00
        expect(household_enrollment_record.sum_fee_of_type(:annual_contribution_fee)).to be 30.00
        expect(household_enrollment_record.sum_fee_of_type(:card_replacement_fee)).to be 5.00
        expect(household_enrollment_record.sum_fee_of_type(:other_fee)).to be 200.00
        expect(household_enrollment_record.sum_fee_of_type(:penalty_fee)).to be 0.30
        expect(household_enrollment_record.sum_fee_of_type(:qualifying_beneficiaries_fee)).to be 0.50
      end
    end
  end
end
