require 'rails_helper'

RSpec.describe CardBatch, type: :model do
  describe '#generate_ids' do
    it 'creates a set of IDs assigned to this batch' do
      batch = create(:card_batch)

      expect(CardIdGenerator).to receive(:unique).exactly(5).times.and_call_original
      expect do
        expect(batch.generate_ids(5).size).to be 5
      end.to change(Card, :count).by(5)
    end

    context 'when prefix is defined' do
      it 'creates a set of IDs assigned to this batch' do
        batch = create(:card_batch)

        expect(CardIdGenerator).to receive(:unique).with(batch.prefix).exactly(5).times.and_call_original
        expect do
          expect(batch.generate_ids(5).size).to be 5
        end.to change(Card, :count).by(5)
      end
    end
  end

  describe 'Validations' do
    context 'when prefix is set' do
      it 'ensures prefix is valid' do
        expect(build(:card_batch, prefix: nil)).to_not be_valid
        expect(build(:card_batch, prefix: 'ETH3')).to_not be_valid
        expect(build(:card_batch, prefix: '123')).to_not be_valid
        expect(build(:card_batch, prefix: 'ABC')).to be_valid
      end
    end
  end
end
