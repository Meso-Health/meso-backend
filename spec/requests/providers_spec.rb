require 'rails_helper'

RSpec.describe "Provider", type: :request do
  describe "GET /providers" do
    let(:readable_provider_fields) { %w[id name provider_type administrative_division_id] }
    it "returns a list of all providers" do
      providers = create_list(:provider, 3)

      get providers_url, headers: token_auth_header, as: :json
      expect(response).to be_successful
      expect(json.size).to eq 3
      expect(json.first.keys).to match_array(readable_provider_fields)
      expect(json.map { |b| b.fetch('id') }).to match_array(providers.map(&:id))
    end
  end
end
