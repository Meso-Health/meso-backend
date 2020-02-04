require 'rails_helper'
require 'csv'

RSpec.describe "PriceSchedules", type: :request do
  let(:test_file_path) { 'tmp/test.csv' }

  describe "POST /admin/price_schedules/import" do
    let!(:password) { 'password' }
    let!(:system_admin) { create(:user, :system_admin, password: password) }
    let!(:provider) { create(:provider) }
    let!(:price_schedule1) { create(:price_schedule, provider: provider) }
    let!(:price_schedule2) { create(:price_schedule, provider: provider) }
    let!(:auth_headers) {
      { 'HTTP_AUTHORIZATION': ActionController::HttpAuthentication::Basic.encode_credentials(system_admin.username, password) }
    }

    before do
      expect do
        post import_admin_price_schedules_url, params: { file: file }, headers: auth_headers
      end.to change(PriceSchedule, :count).by(price_schedules_created_count)
    end

    context 'when the csv is valid' do
      let(:file) { make_csv(
        [
          ['billable_id', 'provider_id', 'price'],
          [price_schedule1.billable.id, provider.id, 100],
          [price_schedule2.billable.id, provider.id, 200],
        ]
      )}
      let(:price_schedules_created_count) { 2 }

      it "imports a list of price schedules successfully" do
        expect(response).to redirect_to(admin_price_schedules_url)
        billable = price_schedule1.billable
        expect(billable.active_price_schedule_for_provider(provider.id).price).to eq 100
        billable2 = price_schedule2.billable
        expect(billable2.active_price_schedule_for_provider(provider.id).price).to eq 200
      end
    end

    context 'when the csv contains a price that is not new' do
      let(:file) { make_csv(
        [
          ['billable_id', 'provider_id', 'price'],
          [price_schedule1.billable.id, provider.id, price_schedule1.price],
          [price_schedule2.billable.id, provider.id, price_schedule2.price],
        ]
      )}
      let(:price_schedules_created_count) { 0 }

      it "no new price schedules are created" do
        expect(response).to redirect_to(admin_price_schedules_url)
      end
    end

    context 'when the CSV has an invalid billable ID' do
      let(:file) { make_csv(
        [
          ['billable_id', 'provider_id', 'price'],
          [price_schedule2.billable.id, provider.id, 200],
          ['random billable id', provider.id, 100],
        ]
      )}
      let(:price_schedules_created_count) { 0 }

      it "flashes an error" do
        expect(response).to redirect_to(admin_price_schedules_url)
        expect(flash[:error]).to_not be_blank
      end
    end

    context 'when the has an invalid provider ID' do
      let(:file) { make_csv(
        [
          ['billable_id', 'provider_id', 'price'],
          [price_schedule1.billable.id, provider.id, 100],
          [price_schedule2.billable.id, 999999999, 200],
        ]
      )}
      let(:price_schedules_created_count) { 0 }

      it "flashes an error" do
        expect(response).to redirect_to(admin_price_schedules_url)
        expect(flash[:error]).to_not be_blank
      end
    end

    context 'when the CSV has an invalid price' do
      let(:file) { make_csv(
        [
          ['billable_id', 'provider_id', 'price'],
          [price_schedule2.billable.id, provider.id, -200],
        ]
      )}
      let(:price_schedules_created_count) { 0 }

      it "flashes an error" do
        expect(response).to redirect_to(admin_price_schedules_url)
        expect(flash[:error]).to_not be_blank
      end
    end
  end

  def make_csv(rows)
    CSV.open(test_file_path, "w") do |csv|
      rows.each do |row|
        csv << row
      end
    end
    fixture_file_upload(test_file_path)
  end
end
