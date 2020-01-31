require 'rails_helper'

RSpec.describe "Household Enrollment Records", type: :request do
  let(:readable_household_enrollment_record_fields) do
    %w[id enrolled_at user_id enrollment_period_id household_id paying renewal administrative_division_id]
  end
  let(:readable_household_fields) do
    %w[id enrolled_at members member_enrollment_records active_membership_payments active_household_enrollment_record administrative_division_id address]
  end
  let(:readable_membership_payment_fields) do
    %w[id receipt_number payment_date annual_contribution_fee registration_fee qualifying_beneficiaries_fee penalty_fee other_fee card_replacement_fee household_enrollment_record_id]
  end
  let(:readable_member_fields) do
    %w[id household_id card_id enrolled_at full_name gender birthdate birthdate_accuracy phone_number medical_record_number photo_url relationship_to_head profession membership_number archived_at archived_reason]
  end
  let(:readable_member_enrollment_record_fields) do
    %w[id enrolled_at user_id member_id note membership_number enrollment_period_id]
  end

  describe "GET /household_enrollment_records" do
    let!(:administrative_division_parent) { create(:administrative_division)}
    let!(:administrative_division1) { create(:administrative_division, parent_id: administrative_division_parent.id)}
    let!(:administrative_division2) { create(:administrative_division, parent_id: administrative_division_parent.id)}
    let!(:administrative_division_no_active_enrollment) { create(:administrative_division) }
    let!(:old_enrollment_period) { create(:enrollment_period, administrative_division: administrative_division_parent) }
    let!(:current_enrollment_period) { create(:enrollment_period, :in_progress, administrative_division: administrative_division_parent) }
    let!(:user1) { create(:user, :enrollment, administrative_division_id: administrative_division_parent.id) }
    let!(:user2) { create(:user, :enrollment, administrative_division_id: administrative_division1.id) }
    let!(:user3) { create(:user, :enrollment, administrative_division_id: administrative_division2.id) }
    let!(:user) { create(:user) }
    let!(:user_whose_admin_division_has_no_active_enrollment_period) { create(:user, :enrollment, administrative_division: administrative_division_no_active_enrollment) }

    let!(:household1) { create(:household, :with_members, members_count: 2, administrative_division: administrative_division1) }
    let!(:household2) { create(:household, :with_members, members_count: 1, administrative_division: administrative_division1) }
    let!(:household3) { create(:household, administrative_division: administrative_division1) }
    let!(:household4) { create(:household, :with_members, members_count: 3, administrative_division: administrative_division1) }
    let!(:household5) { create(:household, :with_members, members_count: 4, administrative_division: administrative_division1) }
    let!(:household6) { create(:household, :with_members, members_count: 5, administrative_division: administrative_division1) }
    let!(:household7) { create(:household, :with_members, members_count: 4, administrative_division: administrative_division2) }
    let!(:household8) { create(:household, :with_members, members_count: 5, administrative_division: administrative_division2) }

    let!(:member_enrollment_record) { create(:member_enrollment_record, member: household1.members.first, enrollment_period: current_enrollment_period) }

    let!(:household_enrollment_record1) { create(:household_enrollment_record, :with_membership_payments, household: household1, enrollment_period: current_enrollment_period) }
    let!(:membership_payment1) { create(:membership_payment, household_enrollment_record: household_enrollment_record1) }
    let!(:household_enrollment_record_old1) { create(:household_enrollment_record, :with_membership_payments, household: household1, enrollment_period: old_enrollment_period) }
    let!(:household_enrollment_record2) { create(:household_enrollment_record, household: household2, enrollment_period: current_enrollment_period) }
    let!(:household_enrollment_record3) { create(:household_enrollment_record, household: household3, enrollment_period: current_enrollment_period) }
    let!(:household_enrollment_record4) { create(:household_enrollment_record, household: household4, enrollment_period: old_enrollment_period) }
    let!(:household_enrollment_record5) { create(:household_enrollment_record, household: household5) }

    let!(:household_enrollment_record7) { create(:household_enrollment_record, household: household7) }
    let!(:household_enrollment_record8) { create(:household_enrollment_record, household: household8) }

    context 'when valid request for households from the parent division' do
      before do
        get household_enrollment_records_url, headers: token_auth_header(user1), as: :json
      end

      it 'returns the households from first admin division in the correct structure' do
        expect(response).to be_successful
        expect(json.size).to eq 8
      end
    end

    context 'when valid request for households from 2nd admin division' do
      before do
        get household_enrollment_records_url, headers: token_auth_header(user3), as: :json
      end

      it 'returns the households from first admin division in the correct structure' do
        expect(response).to be_successful
        expect(json.size).to eq 2
      end
    end

    context 'when invalid request for a user without an admin division' do
      before do
        get household_enrollment_records_url, headers: token_auth_header(user), as: :json
      end

      it 'returns 422' do
        expect(response).to have_http_status(422)
        expect(json.fetch('errors')).to_not be_nil
      end
    end

    context 'when valid request for households from first admin division' do
      before do
        get household_enrollment_records_url, headers: token_auth_header(user2), as: :json
      end

      it 'returns the households from first admin division in the correct structure' do
        expect(response).to be_successful
        expect(json.size).to eq 6

        json.each do |household_json|
          expect(household_json.keys).to match_array(readable_household_fields)
        end

        members_json = json.first.fetch("members")
        members_json.each do |member_json|
          expect(member_json.keys).to match_array(readable_member_fields)
        end
        expect(members_json.size).to eq 2

        member_enrollment_records_json = json.first.fetch("member_enrollment_records")
        expect(member_enrollment_records_json.first.keys).to match_array(readable_member_enrollment_record_fields)
        expect(member_enrollment_records_json.size).to eq 1

        membership_payments_json = json.first.fetch("active_membership_payments")
        expect(membership_payments_json.first.fetch("id")).to eq household_enrollment_record1.membership_payments.first.id
        expect(membership_payments_json.second.fetch("id")).to eq membership_payment1.id
        expect(membership_payments_json.first.keys).to match_array(readable_membership_payment_fields)
        expect(membership_payments_json.size).to eq 2

        active_household_enrollment_record_json = json.first.fetch("active_household_enrollment_record")
        expect(active_household_enrollment_record_json["id"]).to eq household_enrollment_record1.id
        expect(active_household_enrollment_record_json.keys).to match_array(readable_household_enrollment_record_fields)
      end

      context 'subsequent request' do
        before do
          PaperTrail.without_versioning { model_change }
          get household_enrollment_records_url, headers: token_auth_header(user2, additional_headers: {'HTTP_IF_NONE_MATCH' => response.headers['ETag']}), as: :json
        end

        context 'there has been no CHANGES' do
          let(:model_change) { nil }

          it 'returns a not modified response' do
            expect(response).to have_http_status(:not_modified)
          end
        end

        context 'A new household enrollment record was created' do
          let(:model_change) { create(:household_enrollment_record, enrollment_period: current_enrollment_period) }

          it 'returns a not modified response' do
            expect(response).to be_successful
          end
        end

        context 'A new member enrollment record was created' do
          let(:model_change) { create(:member_enrollment_record, enrollment_period: current_enrollment_period) }

          it 'returns a not modified response' do
            expect(response).to be_successful
          end
        end

        context 'A new member enrollment record was created for existing member' do
          let(:model_change) { create(:member_enrollment_record,
            enrollment_period: current_enrollment_period,
            member: household6.members.first
          ) }

          it 'returns a not modified response' do
            expect(response).to be_successful
          end
        end

        context 'A new member was created' do
          let(:model_change) { create(:member, household: household1) }

          it 'returns the updated households' do
            expect(response).to be_successful
          end
        end

        context 'A new household was created' do
          let(:model_change) { create(:household) }

          it 'returns the updated households' do
            expect(response).to have_http_status(:not_modified)
          end
        end

        context 'A household was edited' do
          let(:model_change) { household1.update_attribute(:updated_at, 2.days.from_now) }

          it 'returns the updated households' do
            expect(response).to be_successful
          end
        end

        context 'A member has been edited' do
          let(:model_change) { household1.members.last.update_attribute(:updated_at, 2.days.from_now) }

          it 'returns the updated households' do
            expect(response).to be_successful
          end
        end

        context 'A membership_payment has been created' do
          let(:model_change) { create(:membership_payment, household_enrollment_record: household_enrollment_record1) }

          it 'returns the updated households' do
            expect(response).to be_successful
          end
        end
      end
    end
  end

  describe "POST /household_enrollment_records" do
    let!(:current_enrollment_period) { create(:enrollment_period, :in_progress) }
    let!(:user) { create(:user, :enrollment) }
    let!(:params) {
      attributes_for(:household_enrollment_record)
        .slice(:id, :enrolled_at, :paying)
        .merge(user_id: user.id, enrollment_period_id: current_enrollment_period.id)
    }

    context 'household already exists' do
      let!(:household) { create(:household) }

      it "creates a household enrollment record", use_database_rewinder: true do
        params_with_valid_household_id = params.merge(
          household_id: household.id
        )

        expect do
          post household_enrollment_records_url, params: params_with_valid_household_id, headers: token_auth_header(user), as: :json
        end.to change(HouseholdEnrollmentRecord, :count).by(1).
          and change(Household, :count).by(0)

        expect(response).to be_created
      end
    end

    context 'household does not exist yet' do
      it "creates a household enrollment record", use_database_rewinder: true do
        params_with_non_persisted_household_id = params.merge(
          household_id: build(:household).id
        )

        expect do
          post household_enrollment_records_url, params: params_with_non_persisted_household_id, headers: token_auth_header(user), as: :json
        end.to change(HouseholdEnrollmentRecord, :count).by(0).
          and change(Household, :count).by(0)

        expect(response).to have_http_status(422)
      end
    end
  end
end
