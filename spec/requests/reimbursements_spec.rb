require 'rails_helper'

RSpec.describe "Reimbursements", type: :request do
  let(:provider1) { create(:provider) }
  let(:provider2) { create(:provider) }
  let!(:user) { create(:user) }
  let!(:provider1_reimbursements) { create_list(:reimbursement, 3, :completed, provider: provider1) }
  let!(:provider2_reimbursements) { create_list(:reimbursement, 3, :completed, provider: provider2) }
  let!(:incomplete_reimbursement) { create(:reimbursement, provider: provider1) }
  let!(:claims_with_incomplete_reimbursement) { create_list(:encounter, 5, :approved, provider: provider1, reimbursement_id: incomplete_reimbursement.id) }
  let!(:approved_encounter) { create(:encounter, :approved, provider: provider1) }

  describe "GET /reimbursements" do
    before do
      get reimbursements_url, headers: token_auth_header(user), as: :json
    end

    it "returns a list of all reimbursements for all providers", use_database_rewinder: true  do
      expect(response).to be_successful
      expect(json.size).to eq 7
      expect(json.first.keys).to match_array(%w[completed_at created_at id provider_id payment_date payment_field total updated_at user_id encounter_ids claim_count start_date end_date])
      reimbursements = provider1_reimbursements + provider2_reimbursements
      expect(json.map { |b| b.fetch('id') }).to match_array(reimbursements.map(&:id) + [incomplete_reimbursement.id])
    end
  end

  describe "GET /reimbursements" do
    before do
      get reimbursements_url, headers: token_auth_header(user), params: { provider_id: provider2.id }, as: :json
    end

    it "returns a list of all reimbursements for provider 2", use_database_rewinder: true  do
      expect(response).to be_successful
      expect(json.size).to eq 3
      expect(json.first.keys).to match_array(%w[completed_at created_at id provider_id payment_date payment_field total updated_at user_id encounter_ids claim_count start_date end_date])
      expect(json.map { |b| b.fetch('id') }).to match_array(provider2_reimbursements.map(&:id))
    end
  end


  describe "POST /providers/1/reimbursements", use_database_rewinder: true do
    let(:expected_reimbursement_changes) { 0 }

    before do
      expect do
        post provider_reimbursements_url(provider1), headers: token_auth_header(user), params: params, as: :json
      end.to change(Reimbursement, :count).by(expected_reimbursement_changes)
    end
    context 'when the list of encounter_ids are not included in the request' do
      let(:params) { attributes_for(:reimbursement).slice(:total) }

      it "returns 422 with proper error message" do
        expect(response).to have_http_status(422)
        expect(json.fetch('errors')).to_not be_nil
      end
    end

    context 'when the list of encounter_ids are invalid ids' do
      let(:params) { attributes_for(:reimbursement).slice(:total).merge(encounter_ids: [SecureRandom.uuid]) }

      it "returns 422 with proper error message" do
        expect(response).to have_http_status(422)
        expect(json.fetch('errors')).to_not be_nil
      end
    end

    context 'when the list of encounter_ids correspond to encounters that are not approved' do
      let(:encounter) { create(:encounter, adjudication_state: 'pending', provider: provider1) }
      let(:params) { attributes_for(:reimbursement).slice(:total).merge(encounter_ids: [encounter.id]) }

      it "returns 422 with proper error message" do
        expect(response).to have_http_status(422)
        expect(json.fetch('errors')).to_not be_nil
      end
    end

    context 'when the list of encounter_ids correspond to encounters that are from a different provider' do
      let(:another_provider) { create(:provider) }
      let(:encounter) { create(:encounter, :approved, provider: another_provider) }
      let(:params) { attributes_for(:reimbursement).slice(:total).merge(encounter_ids: [encounter.id]) }

      it "returns 422 with proper error message" do
        expect(response).to have_http_status(422)
        expect(json.fetch('errors')).to_not be_nil
      end
    end

    context 'when the list of encounter_ids correspond to encounters that already have a reimbursement_id' do
      let!(:encounter_with_reimbursement) { create(:encounter, :approved, provider: provider1, reimbursement: provider1_reimbursements.first) }
      let(:params) { attributes_for(:reimbursement).slice(:total).merge(encounter_ids: [encounter_with_reimbursement.id]) }

      it "returns 422 with proper error message" do
        expect(response).to have_http_status(422)
        expect(json.fetch('errors')).to_not be_nil
      end
    end

    context 'when the list of encounter_ids correspond to approved, unreimbursed encounters' do
      let(:expected_reimbursement_changes) { 1 }
      let(:params) { attributes_for(:reimbursement).slice(:total).merge(encounter_ids: [approved_encounter.id]) }

      it "returns http code acceptable" do
        expect(response).to be_successful
      end
    end
  end

  describe "PATCH /reimbursements/:id", use_database_rewinder: true do
    before do
      patch reimbursement_url(reimbursement), headers: token_auth_header(user), params: params, as: :json
    end

    context 'when the reimbursement is already complete and the total is edited' do
      let!(:reimbursement) { create(:reimbursement, :completed, provider: provider1) }
      let(:params) { reimbursement.attributes.symbolize_keys.merge(total: 2500, encounter_ids: [approved_encounter.id]).slice(:id, :total, :encounter_ids) }

      it "returns 405 with proper error message" do
        expect(response).to have_http_status(405)
        expect(json.fetch('errors')).to_not be_nil
      end
    end

    context 'when the list of encounter_ids are included in the request are invalid ids' do
      let!(:reimbursement) { create(:reimbursement, provider: provider1) }
      let(:params) { reimbursement.attributes.symbolize_keys.slice(:total).merge(encounter_ids: [SecureRandom.uuid]) }

      it "returns 422 with proper error message" do
        expect(response).to have_http_status(422)
        expect(json.fetch('errors')).to_not be_nil
      end
    end

    context 'when the list of encounter_ids correspond to encounters with different reimbursement id' do
      let!(:reimbursement) { create(:reimbursement, provider: provider1) }
      let!(:encounter_with_reimbursement) { create(:encounter, :approved, provider: provider1, reimbursement: provider1_reimbursements.first) }
      let(:params) { reimbursement.attributes.symbolize_keys.slice(:total).merge(encounter_ids: [encounter_with_reimbursement.id]) }

      it "returns 422 with proper error message" do
        expect(response).to have_http_status(422)
        expect(json.fetch('errors')).to_not be_nil
      end
    end

    context 'when the list of encounter_ids correspond to encounters that are not approved' do
      let!(:reimbursement) { create(:reimbursement, provider: provider1) }
      let(:unapproved_encounter) { create(:encounter, adjudication_state: 'pending', provider: provider1) }
      let(:params) { reimbursement.attributes.symbolize_keys.slice(:total).merge(encounter_ids: [unapproved_encounter.id]) }

      it "returns 422 with proper error message" do
        expect(response).to have_http_status(422)
        expect(json.fetch('errors')).to_not be_nil
      end
    end

    context 'when the reimbursement is incomplete and the total is edited' do
      let!(:reimbursement) { create(:reimbursement, provider: provider1) }
      let(:params) { reimbursement.attributes.symbolize_keys.merge(total: 2500, encounter_ids: [approved_encounter.id]).slice(:id, :total, :encounter_ids) }

      it "successful patch" do
        expect(response).to be_successful
        expect(reimbursement.reload.total).to eq 2500
        expect(approved_encounter.reload.reimbursement_id.present?).to be true
      end
    end

    context 'when the reimbursement is incomplete and the list of encounters is smaller' do
      let!(:reimbursement) { incomplete_reimbursement }
      let(:params) { reimbursement.attributes.symbolize_keys.merge(total: approved_encounter.reimbursal_amount, encounter_ids: [approved_encounter.id]).slice(:id, :total, :encounter_ids) }

      it "successful patch and old encounters attached to the reimbursements no longer have reimbursements on them" do
        expect(response).to be_successful
        expect(reimbursement.reload.total).to eq approved_encounter.reimbursal_amount
        expect(approved_encounter.reload.reimbursement_id.present?).to be true
        claims_with_incomplete_reimbursement.each do |encounter|
          expect(encounter.reload.reimbursement_id).to be nil
        end
        expect(json.fetch('encounter_ids')).to eq [approved_encounter.id]
      end
    end

    context 'when the reimbursement is incomplete and the patch has no encounter_ids and no payment details' do
      let(:reimbursement) { create(:reimbursement, provider: provider1) }
      let(:params) { reimbursement.attributes.symbolize_keys.slice(:id, :total) }

      it "returns 422 with proper error message" do
        expect(response).to have_http_status(422)
        expect(json.fetch('errors')).to_not be_nil
      end
    end

    context 'when the reimbursement is incomplete and the patch includes both payment details and encounter_ids' do
      let!(:reimbursement) { create(:reimbursement, provider: provider1) }
      let(:params) { reimbursement.attributes.symbolize_keys.merge(
        payment_date: Time.zone.now.to_date,
        payment_field: {
          bank_transfer_number: '12345',
          other_stuff: 'blahblahblah'
        },
        encounter_ids: [approved_encounter.id]
      )}

      it "returns 422 with proper error message" do
        expect(response).to have_http_status(422)
        expect(json.fetch('errors')).to_not be_nil
      end
    end

    context 'when the reimbursement is incomplete and the patch includes payment details and no encounter_ids' do
      let!(:reimbursement) { create(:reimbursement, provider: provider1) }
      let(:params) { reimbursement.attributes.symbolize_keys.merge(
        payment_date: Time.zone.now.to_date,
        payment_field: {
          bank_transfer_number: '12345',
          other_stuff: 'blahblahblah'
        }
      )}

      it "adds the payment info successfully" do
        expect(response).to be_successful
        expect(reimbursement.reload.payment_date.present?).to be true
        expect(reimbursement.reload.payment_field.present?).to be true
        expect(reimbursement.reload.completed_at.present?).to be true
      end
    end
  end

  describe "GET /reimbursements/reimbursable_claims_metadata", use_database_rewinder: true do
    let(:fields) {%w[
      total_price
      start_date
      end_date
      encounter_ids]}
    let(:ad) { create(:administrative_division, :first) }
    let(:provider2) { create(:provider, administrative_division: ad) }
    let(:reimbursement_encounter) { create(:encounter, :approved, provider: provider2, adjudicated_at: Time.zone.now - 1.day) }
    let(:reimbursement1) { create(:reimbursement, encounters: [reimbursement_encounter], provider: provider2) }

    before do
      free_encounters = create_list(:encounter, 2, :approved, provider: provider2, adjudicated_at: Time.zone.now - 1.day)

      get reimbursable_claims_metadata_reimbursements_url, headers: token_auth_header(user), params: params, as: :json
    end

    context 'when no reimbursement id specified' do
      let(:params) do { provider_id: provider2.id, end_date: Time.zone.now } end

      it "returns all approved encounters without reimbursement_id" do
        expect(response).to be_successful
        expect(json.size).to eq 4
        expect(json.keys).to match_array(fields)
        expect(json.fetch('encounter_ids').size).to eq 2
      end
    end

    context 'when reimbursement id specified' do
      let(:params) do { provider_id: provider2.id, reimbursement_id: reimbursement1.id, end_date: Time.zone.now } end

      it "returns all approved encounters without reimbursement_id OR reimbursement_id in params" do
        expect(response).to be_successful
        expect(json.size).to eq 4
        expect(json.keys).to match_array(fields)
        expect(json.fetch('encounter_ids').size).to eq 3
      end
    end

    context 'when no end date specified' do
      let(:params) do { provider_id: provider2.id, reimbursement_id: reimbursement1.id } end

      it "returns 400" do
        expect(response).to have_http_status(400)
      end
    end
  end

  describe "GET /reimbursements/stats", use_database_rewinder: true do
    let(:stats_fields) { %w[
        provider_id
        last_payment_date
        approved
        pending
        returned
        rejected
        total ] }
    let!(:provider) { create(:provider) }
    let!(:pending_encounter1) { create(:encounter, :pending, provider: provider, custom_reimbursal_amount: 700) }
    let!(:pending_encounter2) { create(:encounter, :pending, provider: provider, custom_reimbursal_amount: 200) }
    let!(:pending_encounter3) { create(:encounter, :pending, provider: provider, custom_reimbursal_amount: 300) }
    let!(:approved_encounter1) { create(:encounter, :approved, provider: provider, custom_reimbursal_amount: 800) }
    let!(:approved_encounter2) { create(:encounter, :approved, provider: provider, custom_reimbursal_amount: 900) }
    let!(:approved_encounter3) { create(:encounter, :approved, provider: provider, custom_reimbursal_amount: 100) }
    let!(:approved_encounter4) { create(:encounter, :approved, provider: provider, custom_reimbursal_amount: 200) }
    let!(:returned_encounter1) { create(:encounter, :returned, provider: provider, custom_reimbursal_amount: 400) }
    let!(:returned_encounter2) { create(:encounter, :returned, provider: provider, custom_reimbursal_amount: 500) }
    let!(:returned_encounter3) { create(:encounter, :returned, provider: provider, custom_reimbursal_amount: 400) }
    let!(:rejected_encounter1) { create(:encounter, :rejected, provider: provider, custom_reimbursal_amount: 10700) }

    before do
      get stats_reimbursements_url, headers: token_auth_header(user), params: params, as: :json
    end

    context 'when no provider specified' do
      let(:params) do { provider_id: nil } end
      it "returns stats for all providers" do
        expect(response).to be_successful
        expect(json.size).to eq 3
        expect(json.first.keys).to match_array(stats_fields)
      end
    end

    context 'when the provider is provided' do

      let(:params) do { provider_id: provider.id } end
      it "returns stats only for that provider" do
        expect(response).to be_successful
        expect(json.size).to eq 1
        expect(json.first.keys).to match_array(stats_fields)
        expect(json.first.fetch('last_payment_date')).to be_nil
        expect(json.first.fetch('approved').fetch('claims_count')).to be 4
        expect(json.first.fetch('approved').fetch('total_price')).to eq 2000
        expect(json.first.fetch('pending').fetch('claims_count')).to eq 3
        expect(json.first.fetch('pending').fetch('total_price')).to eq 1200
        expect(json.first.fetch('returned').fetch('claims_count')).to eq 3
        expect(json.first.fetch('returned').fetch('total_price')).to eq 1300
        expect(json.first.fetch('rejected').fetch('claims_count')).to eq 1
        expect(json.first.fetch('rejected').fetch('total_price')).to eq 10700
        expect(json.first.fetch('total').fetch('claims_count')).to eq 10
        expect(json.first.fetch('total').fetch('total_price')).to eq 4500
      end
    end
  end
end
