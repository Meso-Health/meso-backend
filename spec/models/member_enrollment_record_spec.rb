require 'rails_helper'

RSpec.describe MemberEnrollmentRecord, type: :model do
  describe 'Validations' do
    let(:member) { build(:member) }

    describe 'note' do
      it 'does not allow a note if the record does not need review' do
        expect(build(:member_enrollment_record, member: member, note: 'foo', needs_review: false)).to_not be_valid
        expect(build(:member_enrollment_record, member: member, note: 'foo', needs_review: true)).to be_valid
        expect(build(:member_enrollment_record, member: member, note: nil, needs_review: true)).to be_valid
      end
    end

    describe 'card_id' do
      let(:member) { build(:member, card_id: card_id) }
      subject { build(:member_enrollment_record, member: member) }

      context 'does not correspond to an existing card' do
        let(:card_id) { 'RWI123456' }

        it 'is invalid' do
          expect(subject).to_not be_valid
        end
      end

      context 'is associated with a card assigned to a different member' do
        let(:card_id) { create(:member).card_id }

        it 'is invalid' do
          expect(subject).to_not be_valid
        end
      end

      context 'is available' do
        let(:card_id) { create(:card).id }

        it 'is valid' do
          expect(subject).to be_valid
        end
      end
    end
  end
end
