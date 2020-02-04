require 'rails_helper'

RSpec.describe Diagnosis, type: :model do
  describe '.active' do
    let!(:d1) { create(:diagnosis, active: true) }
    let!(:d2) { create(:diagnosis, active: false) }
    let!(:d3) { create(:diagnosis, active: true) }

    it 'selects active diagnoses' do
      expect(Diagnosis.active).to match_array([d1, d3])
    end
  end
end
