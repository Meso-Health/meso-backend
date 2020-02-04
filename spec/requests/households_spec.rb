require 'rails_helper'

RSpec.describe "Households", type: :request do
  let!(:readable_household_fields) {
    %w[administrative_division_id enrolled_at id address members]
  }
  describe "POST /households" do
    let!(:user) { create(:user, :enrollment) }
    let!(:administrative_division) { create(:administrative_division) }
    let!(:params) {
      attributes_for(:household).slice(:id, :enrolled_at, :address).merge(administrative_division_id: administrative_division.id)
    }

    context 'when the request is valid' do
      it "creates a household", use_database_rewinder: true do
        expect do
          post households_url, params: params, headers: token_auth_header(user), as: :json
        end.to change(Household, :count).by(1)

        expect(response).to be_created
      end
    end
  end

  describe "GET /households/search" do
    let(:members_membership_number1) { create_list(:member, 2, membership_number: "987654") }
    let(:member_membership_number2) { create(:member, membership_number: "123456") }
    let(:provider_user1) { create(:user, :identification) }
    let(:provider_user2) { create(:user, :identification) }
    let(:adjudication_user) { create(:user, :adjudication) }
    let(:enrollment_user) { create(:user, :enrollment) }
    let!(:member_with_mrns1) { create(:member, medical_record_numbers: {
      "#{provider_user1.provider.id}": "1234",
      "#{provider_user2.provider.id}": "2345",
      "primary": "3456"
    })}

    context "search by medical_record_number" do
      context "member search via MRN as adjudication user" do
        before do
          get search_households_url(medical_record_number: 3456), headers: token_auth_header(adjudication_user), as: :json
        end

        it 'returns no members because admin should not need to do this' do
          expect(response).to be_successful
          expect(json.size).to eq 0
        end
      end

      context "member search via MRN as enrollment user" do
        before do
          get search_households_url(medical_record_number: 3456), headers: token_auth_header(enrollment_user), as: :json
        end

        it 'returns a list of matching households and their members' do
          expect(response).to be_successful
          expect(json.size).to eq 1
          expect(json.first["members"].size).to eq 1
          expect(json.first["members"].first["id"]).to eq member_with_mrns1.id
        end
      end

      context "member search via primary MRN as a provider user" do
        before do
          get search_households_url(medical_record_number: 3456), headers: token_auth_header(provider_user1), as: :json
        end

        it 'returns a list of matching households and their members' do
          expect(response).to be_successful
          expect(json.size).to eq 0
        end
      end

      context "member search via provider-specific MRN" do
        before do
          get search_households_url(medical_record_number: 1234), headers: token_auth_header(provider_user1), as: :json
        end

        it 'returns a list of matching households and their members' do
          expect(response).to be_successful
          expect(json.size).to eq 1
          expect(json.first["members"].size).to eq 1
          expect(json.first["members"].first["id"]).to eq member_with_mrns1.id
        end
      end

      context "member search via invalid non-matching MRN" do
        before do
          get search_households_url(medical_record_number: 444), headers: token_auth_header(provider_user2), as: :json
        end

        it 'returns no members' do
          expect(response).to be_successful
          expect(json.size).to eq 0
        end
      end
    end

    context "search by membership_number" do
      context "multiple members found" do
        before do
          get search_households_url(membership_number: members_membership_number1.first.membership_number), headers: token_auth_header, as: :json
        end

        it 'returns a list of all matching households and their members' do
          expect(response).to be_successful
          expect(json.size).to eq 2
          expect(json.map { |h| h.fetch('id') }).to match_array(members_membership_number1.map { |m| m.household.id })
          expect(json.first.keys).to match_array(readable_household_fields)
        end
      end

      context "single member is found" do
        before do
          get search_households_url(membership_number: member_membership_number2.membership_number), headers: token_auth_header, as: :json
        end

        it 'returns a list of all matching households and their members' do
          expect(response).to be_successful
          expect(json.first.fetch('members').size).to eq member_membership_number2.household.members.size
          expect(json.first.keys).to match_array(readable_household_fields)
        end
      end

      context "member not found" do
        before do
          get search_households_url(membership_number: "something that isn't a membership number"), headers: token_auth_header, as: :json
        end

        it 'returns empty array' do
          expect(response).to be_successful
          expect(json).to match_array([])
        end
      end
    end

    context "search by member_id" do
      context "member is found" do
        before do
          get search_households_url(member_id: member_membership_number2.id), headers: token_auth_header, as: :json
        end

        it 'returns a list of household members' do
          expect(response).to be_successful
          expect(json.first.fetch('members').size).to eq member_membership_number2.household.members.size
          expect(json.first.keys).to match_array(readable_household_fields)
        end
      end

      context "member not found" do
        before do
          get search_households_url(member_id: "something that isn't a membership id"), headers: token_auth_header, as: :json
        end

        it 'returns empty array' do
          expect(response).to be_successful
          expect(json).to match_array([])
        end
      end
    end

    context "search by multiple params" do
      before do
        get search_households_url(membership_number: members_membership_number1.first.membership_number, member_id: member_membership_number2.id), headers: token_auth_header, as: :json
      end

      it 'returns list of household members matching all params' do
        expect(response).to be_successful
        expect(json.size).to eq 3
        expect(json.first.fetch('members').size).to eq member_membership_number2.household.members.size
      end
    end
  end
end
