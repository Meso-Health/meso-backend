require 'rails_helper'

RSpec.describe Referral, type: :model do
  describe 'validations' do
    describe 'reason' do
      it 'does not allow referral without reason' do
        expect(build(:referral, reason: nil)).to_not be_valid
        expect(build(:referral, reason: 'investigative_tests')).to be_valid
      end
    end
  end
end
