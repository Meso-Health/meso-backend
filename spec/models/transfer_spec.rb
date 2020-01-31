require 'rails_helper'

RSpec.describe Transfer, type: :model do
  describe 'Validation' do
    specify 'amount is integer greater than 0' do
      expect(build(:transfer, amount: nil)).to_not be_valid
      expect(build(:transfer, amount: -100)).to_not be_valid
      expect(build(:transfer, amount: 0)).to_not be_valid
      expect(build(:transfer, amount: 2500)).to be_valid
    end
  end
end
