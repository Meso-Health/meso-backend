require 'rails_helper'

RSpec.describe Reimbursement, type: :model do
  describe 'Validations' do
    describe 'payment_fields_all_set_or_all_empty' do
      context 'when all payment fields are set to nil' do
        it 'should be valid' do
          expect(build(:reimbursement, :completed, payment_date: nil, payment_field: nil, completed_at: nil)).to be_valid
        end
      end

      context 'when all payment fields are set' do
        it 'should be valid' do
          expect(build(:reimbursement, :completed, payment_date: Time.zone.now.to_date, payment_field: {blah: 123}, completed_at: Time.zone.now)).to be_valid
        end
      end

      context 'when only some payment fields are set' do
        it 'should be not valid' do
          expect(build(:reimbursement, payment_date: nil, payment_field: {blah: 123}, completed_at: Time.zone.now)).to_not be_valid
          expect(build(:reimbursement, payment_date: Time.zone.now.to_date, payment_field: nil, completed_at: Time.zone.now)).to_not be_valid
          expect(build(:reimbursement, payment_date: Time.zone.now.to_date, payment_field: {blah: 123}, completed_at: nil)).to_not be_valid
          expect(build(:reimbursement, payment_date: Time.zone.now.to_date, payment_field: nil, completed_at: nil)).to_not be_valid
        end
      end
    end
  end

  describe '#editable?' do
    context 'when the reimbursement is incomplete' do
      subject { build(:reimbursement) }

      it 'returns true' do
        expect(subject.editable?).to be true
      end
    end

    context 'when the reimbursement is complete' do
      subject { build(:reimbursement, :completed) }

      it 'returns false' do
        expect(subject.editable?).to be false
      end
    end
  end

  describe '.paid' do
    let!(:paid1) { create(:reimbursement, :completed, payment_date: Time.zone.now.to_date, payment_field: { notnil: 1}, completed_at: Time.zone.now) }
    let!(:paid2) { create(:reimbursement, :completed, payment_date: Time.zone.now.to_date, payment_field: { notnil: 1}, completed_at: Time.zone.now) }
    let!(:unpaid1) { create(:reimbursement, payment_date: nil, completed_at: nil, payment_field: nil) }
    let!(:unpaid2) { create(:reimbursement, payment_date: nil, completed_at: nil, payment_field: nil) }

    it 'returns list of paid reimbursements' do
      expect(described_class.paid).to match_array([paid1, paid2])
    end
  end
end
