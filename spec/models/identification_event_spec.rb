require 'rails_helper'

RSpec.describe IdentificationEvent, type: :model do
  describe 'Validations' do
    describe 'through_member' do
      context 'when search_method is through_household' do
        it 'ensured through_member is set' do
          id_event = IdentificationEvent.new(search_method: :through_household)
          id_event.validate
          expect(id_event.errors[:through_member]).to_not be_empty
        end
      end

      context 'when search_method is not through_household' do
        it 'does not require through_member is to be set' do
          id_event = IdentificationEvent.new(search_method: :scan_barcode)
          id_event.validate
          expect(id_event.errors[:through_member]).to be_empty
        end
      end
    end
  end

  describe 'scopes' do
    describe '.is_open' do
      context 'when there are no open identification events' do
        it 'returns an empty array' do
          result = described_class.is_open
          expect(result).to be_empty
        end
      end

      context 'when there are identification events with started encounters' do
        let(:open_identification_event) { create(:identification_event) }
        let(:dismissed_identification_event) { create(:identification_event, :dismissed) }
        let!(:started_encounter1) { create(:encounter, :started, identification_event: open_identification_event) }
        let!(:started_encounter2) { create(:encounter, :started, identification_event: dismissed_identification_event) }

        it 'returns the ones that are not dismissed as open identification events' do
          result = described_class.is_open
          expect(result).to match_array([open_identification_event])
        end
      end
    end
  end
end
