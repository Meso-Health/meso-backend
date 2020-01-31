require 'rails_helper'

RSpec.describe LabResult, type: :model do
  describe 'Validation' do
    specify 'result' do
      expect(build(:lab_result, result: 'positive')).to be_valid
      expect(build(:lab_result, result: 'yes')).to_not be_valid
      expect(build(:lab_result, result: nil)).to_not be_valid
    end
  end
end
