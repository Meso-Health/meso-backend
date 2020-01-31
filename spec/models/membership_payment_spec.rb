require 'rails_helper'

RSpec.describe MembershipPayment, type: :model do
  describe '#total' do
    context 'when all line items are zero' do
      subject { create(:membership_payment) }

      it 'returns 0' do
        expect(subject.total).to eq 0
      end
    end

    context 'when there are some non-zero line items' do
      subject { create(:membership_payment,
        annual_contribution_fee: 200,
        registration_fee: 240,
        qualifying_beneficiaries_fee: 2,
        penalty_fee: 5,
        other_fee: 15,
        card_replacement_fee: 250)
      }

      it 'returns 712' do
        expect(subject.total).to eq 712
      end
    end
  end
end
