require 'rails_helper'

RSpec.describe "Provider Billables", type: :request do
  let(:readable_billable_with_price_schedule_fields) do
    %w[id active_price_schedule active name composition type unit reviewed requires_lab_result accounting_group]
  end
  let(:readable_price_schedule_fields) do
    %w[id price issued_at billable_id provider_id previous_price_schedule_id]
  end

  describe "GET /providers/:id/billables" do
    let!(:provider) { create(:provider) }
    let!(:active_price_schedules) { create_list(:price_schedule, 3, provider: provider, issued_at: 5.days.ago) }
    let!(:inactive_billable) { create(:billable, active: false) }
    let!(:inactive_price_schedule) { create(:price_schedule, billable: inactive_billable, provider: provider) }
    let!(:another_provider) { create(:provider) }
    let!(:billable_from_another_provider) { create(:billable, active: true) }
    let!(:price_schedule_in_another_provider) { create(:price_schedule, provider: another_provider, billable: billable_from_another_provider) }
    let!(:provider_user) { create(:user, :provider_admin, provider: provider) }

    it "returns a list of the active billables of a provider" do
      get provider_billables_url(provider), headers: token_auth_header, as: :json
      expect(response).to be_successful

      expect(json.size).to eq 3
      expect(json.first.keys).to match_array(readable_billable_with_price_schedule_fields)
      expect(json.map { |b| b.fetch('id') }).to match_array(active_price_schedules.map(&:billable_id))

      active_price_schedule = json.first.fetch("active_price_schedule")
      expect(active_price_schedule.keys).to match_array(readable_price_schedule_fields)
    end

    context "returns the correct status code based on staleness of billables with latest price schedule" do
      before do
        get provider_billables_url(provider), headers: token_auth_header, as: :json
      end

      it "should return success the first time" do
        expect(response).to be_successful
      end

      context "subsequent request" do
        before do
          PaperTrail.without_versioning { model_change }
          get provider_billables_url(provider), headers: token_auth_header(provider_user, additional_headers: {"HTTP_IF_NONE_MATCH": response.headers["ETag"]}), as: :json
        end

        context "no changed billables or prices under that provider" do
          let(:model_change) { nil }

          it 'returns a not modified response' do
            expect(response).to have_http_status(:not_modified)
          end
        end

        context "a new billable has been created" do
          let(:model_change) { create(:price_schedule, provider: provider) }

          it 'returns the updated billables' do
            expect(response).to be_successful
          end
        end

        context "a billable has been de-activated" do
          let(:model_change) { provider.billables.active.first.update_attributes(active: false) }

          it 'returns the updated billables' do
            expect(response).to be_successful
          end
        end

        context "a billable has been edited" do
          let(:model_change) { provider.billables.active.first.update_attribute(:updated_at, 2.days.from_now) }

          it 'returns the updated billables' do
            expect(response).to be_successful
          end
        end

        context "a new price schedule has been created for an existing billable" do
          let(:billable_with_new_price_schedule) { provider.billables.first }
          let(:model_change) do
            create(:price_schedule,
              provider: provider,
              billable: billable_with_new_price_schedule,
              issued_at: Time.zone.now,
              previous_price_schedule_id: billable_with_new_price_schedule.price_schedules.first.id
            )
          end

          it 'returns the updated billables' do
            expect(response).to be_successful
          end
        end
      end
    end
  end

  describe "POST /providers/:id/billables" do
    it "creates a billable at a provider", use_database_rewinder: true do
      provider = create(:provider)
      user = create(:user, :provider_admin, provider: provider)

      params = attributes_for(:billable)

      expect do
        post provider_billables_url(provider), params: params, headers: token_auth_header(user), as: :json
      end.to change(Billable, :count).by(1)

      expect(response).to be_created
      expect(json.keys).to match_array(readable_billable_with_price_schedule_fields - ['active_price_schedule'])
      expect(json.fetch('id')).to eq params[:id]
      expect(json.fetch('active')).to eq true
      expect(json.fetch('reviewed')).to eq false
    end
  end
end
