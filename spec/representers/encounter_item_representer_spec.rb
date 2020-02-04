require 'rails_helper'

RSpec.describe EncounterItemRepresenter do
  subject { EncounterItemRepresenter.new(record) }

  describe '#lab_result' do
    describe 'rendering' do
      let(:record) { create(:encounter_item, :with_lab_result) }

      it 'includes the represented lab result' do
        result = subject.to_hash

        lab_result = result.fetch('lab_result')
        expect(lab_result).to be
        expect(lab_result.keys).to match_array(%w[id result])
      end
    end

    describe 'parsing' do
      let(:record) { EncounterItem.new }
      let(:lab_result_attrs) { attributes_for(:lab_result, encounter_item: nil).stringify_keys }
      let!(:billable) { create(:price_schedule, provider: create(:provider)).billable }

      it 'assigns the lab result' do
        hash = attributes_for(:encounter_item).merge(
          lab_result: lab_result_attrs
        ).stringify_keys

        subject.from_hash(hash)
        expect(record.lab_result).to_not be_nil
      end
    end
  end
end
