require 'rails_helper'

RSpec.describe "Provider price schedules", type: :request do
  let!(:provider) { create(:provider) }
  let!(:user) { create(:user, :provider_admin, provider: provider) }
  let!(:price_schedule) { create(:price_schedule, provider: provider, issued_at: 10.days.ago) }
  let!(:billable) { price_schedule.billable }

  describe "POST /providers/:id/price_schedules", use_database_rewinder: true do
    it "creates a price schedule at a provider for existing billable" do
      params = attributes_for(:price_schedule,
        billable_id: billable.id,
        issued_at: 1.days.ago,
        price: 1234,
        previous_price_schedule_id: price_schedule.id
      )

      expect do
        post provider_price_schedules_url(provider), params: params, headers: token_auth_header(user), as: :json
      end.to change(provider.price_schedules, :count).by(1)

      expect(response).to be_created
      expect(json.keys).to match_array(%w[id price issued_at billable_id provider_id previous_price_schedule_id])
      expect(json.fetch('id')).to eq params[:id]
      expect(json.fetch('price')).to eq 1234
      expect(json.fetch('billable_id')).to eq billable.id
      expect(json.fetch('provider_id')).to eq provider.id
      expect(json.fetch('previous_price_schedule_id')).to eq price_schedule.id
    end
  end

  it "does not create a price schedule if provider_id is invalid", use_database_rewinder: true do
    params = attributes_for(:price_schedule,
      billable_id: build(:billable).id,
      issued_at: 1.days.ago,
      price: 1234,
      previous_price_schedule_id: price_schedule.id
    )

    expect do
      post provider_price_schedules_url(provider), params: params, headers: token_auth_header(user), as: :json
    end.to change(provider.price_schedules, :count).by(0)

    expect(response).to have_http_status(422)
  end

  it "does not create a price schedule at a provider without an existing billable", use_database_rewinder: true do
    params = attributes_for(:price_schedule,
      billable_id: build(:billable).id,
      issued_at: 1.days.ago,
      price: 1234,
      previous_price_schedule_id: price_schedule.id
    )

    expect do
      post provider_price_schedules_url(120984021), params: params, headers: token_auth_header(user), as: :json
    end.to change(provider.price_schedules, :count).by(0)

    expect(response).to have_http_status(404)
  end

  it "does not create a price schedule at a provider if previous_price_schedule_id is not included in the request", use_database_rewinder: true do
    params = attributes_for(:price_schedule,
      billable_id: billable.id,
      issued_at: 1.days.ago,
      price: 1234
    )

    expect do
      post provider_price_schedules_url(provider), params: params, headers: token_auth_header(user), as: :json
    end.to change(provider.price_schedules, :count).by(0)

    expect(response).to have_http_status(422)
  end
end
