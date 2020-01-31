require 'rails_helper'

RSpec.describe "Provider Identification Events", type: :request do
  let(:readable_id_event_fields) do
    %w[id occurred_at provider_id member_id user_id accepted search_method photo_verified through_member_id clinic_number clinic_number_type dismissed]
  end

  describe "GET identification_events" do
    let(:provider1) { create(:provider) }
    let(:provider2) { create(:provider) }
    let(:member1) { create(:member, medical_record_numbers: { provider1.id.to_s => '123' }) }
    let(:member2) { create(:member, medical_record_numbers: { provider1.id.to_s => '234' }) }
    let!(:id_event1) { create(:identification_event, provider: provider1, occurred_at: 1.day.ago, member: member1) }
    let!(:id_event2) { create(:identification_event, provider: provider1, occurred_at: 3.days.ago, member: member2) }
    let!(:id_event3) { create(:identification_event, :dismissed, provider: provider1, occurred_at: 1.hour.ago) }
    let!(:id_event4) { create(:identification_event, provider: provider2) }

    describe "GET /providers/:id/identification_events" do
      it "returns a list of identification events at a provider ordered by occurred_at desc" do
        get provider_identification_events_url(provider1), headers: token_auth_header, as: :json

        expect(response).to be_successful
        expect(json.size).to eq 3
        expect(json.map { |x| x.fetch('id') }).to match_array([id_event3.id, id_event1.id, id_event2.id])
        expect(json.first.keys).to match_array(readable_id_event_fields)
      end
    end

    describe "GET /providers/:id/identification_events/open" do
      let!(:encounter1) { create(:encounter, :started, identification_event: id_event1) }
      let!(:encounter2) { create(:encounter, :started, identification_event: id_event2) }
      let!(:encounter3) { create(:encounter, :started, identification_event: id_event3) }
      let!(:encounter4) { create(:encounter, :started, identification_event: id_event4) }
      let(:user) { create(:user, :provider_admin, provider: provider1) }

      before { get open_provider_identification_events_url(provider1), headers: token_auth_header(user), as: :json }

      it "returns a list of open identification events at a provider ordered by occurred_at asc" do
        expect(response).to be_successful
        expect(json.size).to eq 2
        expect(json.map { |x| x.fetch('id') }).to match_array([id_event1.id, id_event2.id])
        expect(json.first.keys).to match_array(readable_id_event_fields + %w[encounter member])
      end

      it 'sets the medical record number based on the current user\'s provider' do
        expect(response).to be_successful
        expect(json.map { |id_event| id_event['member']['medical_record_number']} ).to match_array(['123', '234'])
      end
    end
  end

  describe "POST /providers/:id/identification_events", use_database_rewinder: true do
    let(:provider) { create(:provider) }
    let(:member) { create(:member) }
    let(:user) { create(:user, :identification) }
    let(:params) do
      attributes_for(:identification_event,
                     member_id: member.id,
                     provider_id: nil,
                     user_id: nil)
    end
    let(:excluded_fields) { [] }

    shared_examples :successful_response do
      it 'successfully creates the identification event and returns it in a json response' do
        expect do
          post provider_identification_events_url(provider), params: params, headers: token_auth_header(user), as: :json
        end.to change(IdentificationEvent, :count).by(1)

        expect(response).to be_created
        expect(json.keys).to match_array(readable_id_event_fields - excluded_fields)
        expect(json.fetch('id')).to eq params[:id]
        expect(json.fetch('provider_id')).to eq provider.id
        expect(json.fetch('member_id')).to eq member.id
        expect(json.fetch('user_id')).to eq user.id
      end
    end

    it_behaves_like :successful_response

    context 'when the params has allowable nil fields' do
      let(:params) do
        attributes_for(:identification_event,
                       member_id: member.id,
                       provider_id: nil,
                       user_id: nil,
                       dismissed: nil,
                       accepted: nil,
                       photo_verified: nil)
      end
      let(:excluded_fields) { %w[accepted photo_verified dismissed] }

      it_behaves_like :successful_response
    end
  end

  describe "PATCH /identification_events/:id" do
    let(:provider) { create(:provider) }
    let!(:id_event) { create(:identification_event, provider: provider) }
    let(:params) do
      build(:identification_event, :dismissed)
        .attributes
        .slice('dismissed')
    end

    it "successfully updates the identification event and returns it in a json response" do
      expect do
        patch identification_event_url(id_event), params: params, headers: token_auth_header, as: :json
      end.to change { id_event.reload.updated_at }

      expect(response).to be_successful
      expect(json.keys).to match_array(readable_id_event_fields)

      applied = %w[dismissed dismissal_reason]
      expect(json.slice(*applied)).to eq params.slice(*applied)
    end

    context 'when the params has allowable nil fields' do
      let(:params) do
        build(:identification_event, dismissed: nil, accepted: nil, photo_verified: nil)
          .attributes
      end

      it "successfully updates the identification event and returns it in a json response" do
        expect do
          patch identification_event_url(id_event), params: params, headers: token_auth_header, as: :json
        end.to change { id_event.reload.updated_at }

        expect(response).to be_successful
        expect(json.keys).to match_array(readable_id_event_fields - %w[dismissed accepted photo_verified])
      end
    end
  end
end
