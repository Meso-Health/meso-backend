require 'rails_helper'

RSpec.describe EnrollmentReportingStatsService do
  let(:member) { create(:member) }
  let(:household) { member.household }
  let!(:ad_third) { create(:administrative_division, level: 'third') }
  let!(:ad_fourth) { create(:administrative_division, level: 'fourth', parent: ad_third) }
  let!(:household_enrollment_record) { create(:household_enrollment_record, household: household, administrative_division: ad_fourth) }
  let!(:membership_payment) { create(:membership_payment, household_enrollment_record: household_enrollment_record) }

  describe '#generate_stats' do
    context 'no filters' do
      it 'returns stats based on all enrollment data' do
        result = {
          members: 1,
          beneficiaries: 0,
          membership_payment: {
            annual_contribution_fee: 0,
            qualifying_beneficiaries_fee: 0,
            registration_fee: 0,
            penalty_fee: 0,
            other_fee: 0,
            card_replacement_fee: 0,
          }
        }

        expect(subject.generate_stats).to eq result
      end
    end
  end
end
