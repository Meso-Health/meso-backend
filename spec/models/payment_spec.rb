require 'rails_helper'

RSpec.describe Payment, type: :model do
  describe 'Validations' do
    describe 'transfers' do
     it 'does not allow an empty array' do
       subject = build_stubbed(:capitation_fee_payment, transfers: [])
       expect(subject).to_not be_valid
       expect(subject.errors[:transfers]).to_not be_empty
      end
    end

    describe 'effective_date' do
      it 'only allows dates on the first of the month' do
        subject = build_stubbed(:capitation_fee_payment, effective_date: '2017-03-01')
        expect(subject).to be_valid

        subject = build_stubbed(:capitation_fee_payment, effective_date: '2017-03-02')
        expect(subject).to_not be_valid
        expect(subject.errors[:effective_date]).to_not be_empty

        subject = build_stubbed(:capitation_fee_payment, effective_date: '2015-02-29')
        expect(subject).to_not be_valid
        expect(subject.errors[:effective_date]).to_not be_empty
      end

      it 'does not allow the same payment type for the same provider to be created for the same year-month' do
        provider = create(:provider)
        create(:capitation_fee_payment, provider: provider, effective_date: '2017-02-01')

        subject = build_stubbed(:capitation_fee_payment, provider: provider, effective_date: '2017-02-01')
        expect(subject).to_not be_valid

        subject = build_stubbed(:capitation_fee_payment, provider: provider, effective_date: '2017-03-01')
        expect(subject).to be_valid

        subject = build_stubbed(:capitation_fee_payment, provider: build(:provider), effective_date: '2017-02-01')
        expect(subject).to be_valid

        subject = build_stubbed(:fee_for_service_payment, provider: provider, effective_date: '2017-02-01')
        expect(subject).to be_valid
      end
    end

    describe 'details' do
      context 'when it is a capitation_fee payment' do
        subject { build_stubbed(:capitation_fee_payment, details: {}) }

        it 'requires details' do
          expect(subject).to_not be_valid
          expect(subject.errors[:details]).to_not be_empty

          subject.details['fee_per_member'] = 3500
          expect(subject).to_not be_valid
          expect(subject.errors[:details]).to_not be_empty

          subject.details['member_count'] = 2666
          expect(subject).to be_valid
        end
      end

      context 'when it is a fee_for_service payment' do
        subject { build_stubbed(:fee_for_service_payment, details: {}) }

        it 'does not require details' do
          expect(subject).to be_valid
        end
      end
    end
  end
end
