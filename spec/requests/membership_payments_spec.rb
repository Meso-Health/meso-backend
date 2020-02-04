require 'rails_helper'

RSpec.describe "Membership Payments", type: :request do
  describe "POST /membership_payments" do
    let!(:user) { create(:user, :enrollment) }
    let!(:params) {
      attributes_for(:membership_payment).slice(
        :id,
        :receipt_number,
        :payment_date,
        :annual_contribution_fee,
        :registration_fee,
        :qualifying_beneficiaries_fee,
        :card_replacement_fee,
        :penalty_fee,
        :other_fee
      )
    }

    context 'when the household_enrollment_record has already been persisted' do
      let!(:household_enrollment_record) { create(:household_enrollment_record) }

      it "creates a membership_payment", use_database_rewinder: true do
        params_with_valid_household_enrollment_record = params.merge(
          household_enrollment_record_id: household_enrollment_record.id
        )

        expect do
          post membership_payments_url, params: params_with_valid_household_enrollment_record, headers: token_auth_header(user), as: :json
        end.to change(MembershipPayment, :count).by(1)

        expect(response).to be_created
      end
    end

    context 'when the household_enrollment_record has not been persisted yet' do
      let!(:household_enrollment_record) { build(:household_enrollment_record) }

      it "creates a membership_payment", use_database_rewinder: true do
        params_with_invalid_household_enrollment_record = params.merge(
          household_enrollment_record_id: household_enrollment_record.id
        )

        expect do
          post membership_payments_url, params: params_with_invalid_household_enrollment_record, headers: token_auth_header(user), as: :json
        end.to change(MembershipPayment, :count).by(0)

        expect(response).to have_http_status(422)
      end
    end
  end
end
