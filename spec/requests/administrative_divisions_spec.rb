require 'rails_helper'

RSpec.describe 'AdministrativeDivisions', type: :request do
  describe 'GET /administrative_divisions' do
    let(:second_level_division) { AdministrativeDivision.find_by(level: 'second') }
    let(:user) { create(:user, :enrollment, administrative_division: second_level_division) }

    before do
      create(:administrative_division, :fourth)
      get administrative_divisions_url(within_jurisdiction: within_jurisdiction), headers: token_auth_header(user), as: :json
    end

    context 'no jurisdiction is passed' do
      let(:within_jurisdiction) { 'false' }

      it 'returns a list of the all the administrative_divisions' do
        expect(response).to be_successful
        expect(json.size).to eq 4
        expect(json.first.keys).to match_array(%w[id name level code parent_id])
      end
    end

    context 'jurisdiction is passed' do
      let(:within_jurisdiction) { 'true' }

      it 'only returns administrative divisions associated with the current user' do
        expect(response).to be_successful
        expect(json.size).to eq 3
        expect(json.first.keys).to match_array(%w[id name level code parent_id])
        ids = json.map { |ad| ad['id'] }
        expect(ids).to match_array(AdministrativeDivision.where.not(level: 'first').pluck(:id))
      end
    end
  end
end
