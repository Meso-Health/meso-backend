require 'rails_helper'

RSpec.describe HasAttachment, type: :model do
  let(:model) { ModelWithAttachment.new }

  describe '#save!' do

    before { subject.save! }

    context 'new model with invalid attributes' do
      let(:invalid_member) { build(:member, card_id: '123123') }
      subject { build(:member_enrollment_record, member: invalid_member) }

      it 'persists the record' do
        expect(subject).to be_persisted
      end

      it 'strips any invalid attributes' do
        expect(subject.note).to be_nil
        expect(subject.member.card_id).to be_nil
      end

      it 'assigns the invalid attributes to the invalid_attributes field' do
        expect(subject.invalid_attributes).to eq({
          "member.card_id" => 'does not follow the Meso Card ID format'
        })
      end
    end

    context 'persisted model with non-empty invalid_attributes' do
      let(:invalid_attributes) { { 'member.card_id' => 'is invalid'} }
      let(:member) { create(:member) }
      subject { create(:member_enrollment_record, member: member, invalid_attributes: invalid_attributes) }

      describe 'when the invalid attribute is set to a valid attribute' do
        before { subject.member.card_id = '123123' }

        it 'removes the field from the invalid attributes hash' do
          subject.save!
          expect(subject.invalid_attributes).to eq({ 'member.card_id' => 'does not follow the Meso Card ID format' })
        end
      end

      describe 'when invalid attribute fields are not changed' do
        it 'does not clear the invalid_attributes field' do
          subject.save!
          expect(subject.invalid_attributes).to eq invalid_attributes
        end
      end
    end
  end
end
