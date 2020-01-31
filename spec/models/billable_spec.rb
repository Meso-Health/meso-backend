require 'rails_helper'

RSpec.describe Billable, type: :model do
  describe 'Validation' do
    context 'requires lab result' do
      specify 'must be of type lab' do
        expect(build(:billable, requires_lab_result: true, type: 'drug')).to_not be_valid
        expect(build(:billable, :requires_lab_result)).to be_valid
      end
    end

    context 'requires valid accounting group' do
      specify 'must be nil or in the list of accepted accounting groups' do
        expect(build(:billable, accounting_group: nil)).to be_valid
        expect(build(:billable, accounting_group: 'drug_and_supply')).to be_valid
        expect(build(:billable, accounting_group: 'invalid_accounting_group')).to_not be_valid
      end
    end
  end
end
