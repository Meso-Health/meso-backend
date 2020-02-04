require 'rails_helper'

RSpec.describe EncounterItem, type: :model do
  describe 'Validation' do
    specify 'lab result' do
      expect(build(:encounter_item, :with_lab_result)).to be_valid
      expect(build(:encounter_item, billable: build(:billable), lab_result: nil)).to be_valid
      expect(build(:encounter_item, lab_result: nil, billable: build(:billable, :requires_lab_result))).to be_valid
      expect(build(:encounter_item, lab_result: build(:lab_result), billable: build(:billable, requires_lab_result: false))).to be_valid
    end
  end

  describe '#price' do
    context 'when encounter item is stockout' do
      subject { create(:encounter_item, stockout: true) }

      it 'returns 0' do
        expect(subject.price).to eq 0
      end
    end

    context 'when encounter item is not stockout' do
      let(:price_schedule1) { create(:price_schedule, price: 5) }
      subject { create(:encounter_item, price_schedule: price_schedule1, quantity: 2, stockout: false) }

      it 'returns price schedule price times quantity' do
        expect(subject.price).to eq 10
      end
    end

  end
end
