require 'rails_helper'

RSpec.describe "Diagnoses", type: :request do
  describe "GET /diagnoses" do
    let!(:diagnoses_group1) { create(:diagnoses_group) }
    let!(:diagnoses_group2) { create(:diagnoses_group, diagnoses: [diagnoses_group1.diagnoses.first]) }

    let(:provider1) { create(:provider, diagnoses_group_id: diagnoses_group1.id) }
    let(:provider_user1) { create(:user, :provider_admin, provider: provider1)}

    let(:provider2) { create(:provider, diagnoses_group_id: diagnoses_group2.id) }
    let(:provider_user2) { create(:user, :provider_admin, provider: provider2) }

    let(:provider3) { create(:provider) }
    let(:provider_user3) { create(:user, :provider_admin, provider: provider3) }

    let(:payer_admin_user) { create(:user, :payer_admin) }

    context "if the user is from provider1" do
      before do
        get diagnoses_url, headers: token_auth_header(provider_user1), as: :json
      end

      it "returns a list of the all diagnoses from group 1" do
        expect(response).to be_successful
        expect(json.size).to eq diagnoses_group1.diagnoses.count
        expect(json.map { |d| d["id"] }).to match_array diagnoses_group1.diagnoses.map(&:id)
      end
    end

    context "if the user is from provider2" do
      before do
        get diagnoses_url, headers: token_auth_header(provider_user2), as: :json
      end

      it "returns a list of the all diagnoses from group 2" do
        expect(response).to be_successful
        expect(json.size).to eq diagnoses_group2.diagnoses.count
        expect(json.map { |d| d["id"] }).to match_array diagnoses_group2.diagnoses.map(&:id)
      end
    end

    context "if the user is from provider3" do
      before do
        get diagnoses_url, headers: token_auth_header(provider_user3), as: :json
      end

      it "returns a list of the all diagnoses" do
        expect(response).to be_successful
        expect(json.size).to eq Diagnosis.count
        expect(json.map { |d| d["id"] }).to match_array Diagnosis.all.map(&:id)
      end
    end

    context "if the current user is not from a provider" do
      before do
        get diagnoses_url, headers: token_auth_header(payer_admin_user), as: :json
      end

      it "returns a list of the all diagnoses" do
        expect(response).to be_successful
        expect(json.size).to eq Diagnosis.count
        expect(json.map { |d| d["id"] }).to match_array Diagnosis.all.map(&:id)
      end
    end
  end
end
