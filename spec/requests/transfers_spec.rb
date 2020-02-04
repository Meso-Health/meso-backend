require 'rails_helper'

RSpec.describe 'Transfers', type: :request do
  describe 'POST /transfers' do
    context 'current user is an admin' do
      let(:user) { create(:user, :system_admin) }
      let(:params) {{description: 'Coverage payment', amount: '15000'}}

      before do
        VCR.use_cassette('initiate_stripe_transfer') do
          post transfers_url, params: params, headers: token_auth_header(user), as: :json
        end
      end

      it 'creates and initiates a Transfer' do
        expect(response).to be_created
        expect(json.fetch('amount')).to eq 15000
        expect(json.fetch('description')).to eq 'Coverage payment'
        expect(json.fetch('stripe_account_id')).to eq 'acct_1AUIf0LVHcdVuufE'
        expect(json.fetch('stripe_transfer_id')).to eq 'tr_BOQmOXsAw2c6uD'
        expect(json.fetch('stripe_payout_id')).to eq 'po_1B1duULVHcdVuufESz4XcZ5v'
        expect(json.fetch('user_id')).to eq user.id
      end
    end

    context 'current user is not an admin' do
      let(:user) { create(:user, :provider_admin) }

      before do
        post transfers_url, params: {}, headers: token_auth_header(user), as: :json
      end

      it 'returns a permission error' do
        expect(response).to be_forbidden
      end
    end
  end
end
