require 'rails_helper'

RSpec.describe PilotRegion, type: :model do
  describe 'Validation' do
    let!(:pilot_region) { create(:pilot_region) }

    describe 'administrative_division' do
      it 'does not allow nil administrative_division' do
        expect(build(:pilot_region, administrative_division: nil)).to_not be_valid
      end

      it 'does not allow duplicate administrative_division' do
        expect(build(:pilot_region, administrative_division: pilot_region.administrative_division)).to_not be_valid
      end

      it 'allows new pilot regions with unique administrative_division' do
        expect(build(:pilot_region)).to be_valid
      end
    end
  end
end
