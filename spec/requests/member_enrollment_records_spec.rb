require 'rails_helper'

RSpec.describe "Member Enrollment Records", type: :request do
  describe "POST /member_enrollment_records" do
    let!(:current_enrollment_period) { create(:enrollment_period, :in_progress) }
    let!(:user) { create(:user, :enrollment) }
    let!(:params) {
      attributes_for(:member_enrollment_record)
        .slice(:id, :enrolled_at, :paying, :note)
        .merge(user_id: user.id, enrollment_period_id: current_enrollment_period.id )
    }

    context 'member already exists' do
      let!(:member) { create(:member, membership_number: nil) }
      let(:ad) { create(:administrative_division, :fourth) }
      let!(:household_enrollment_record) { create(:household_enrollment_record, household: member.household, administrative_division: ad) }

      context "when auto membership number generation is enabled" do
        before do
          allow(ENV).to receive(:[]).with("ENABLE_AUTO_MEMBERSHIP_NUMBER_GENERATION").and_return("true")
          allow(ENV).to receive(:[]).with("MEMBERSHIP_NUMBER_LENGTH").and_return("8")
        end

        it "creates a member enrollment record and generates a membership number", use_database_rewinder: true do
          params_with_valid_member_id = params.merge(
            member_id: member.id
          )

          expect do
            post member_enrollment_records_url, params: params_with_valid_member_id, headers: token_auth_header(user), as: :json
          end.to change(MemberEnrollmentRecord, :count).by(1).
            and change(Member, :count).by(0)

          expect(response).to be_created
          expect(member.reload.membership_number).to_not be_nil
        end
      end

      context "when auto membership number generation is not enabled" do
        before do
          allow(ENV).to receive(:[]).with("ENABLE_AUTO_MEMBERSHIP_NUMBER_GENERATION").and_return("false")
        end

        it "creates a member enrollment record without generating a membership_number", use_database_rewinder: true do
          params_with_valid_member_id = params.merge(
            member_id: member.id
          )

          expect do
            post member_enrollment_records_url, params: params_with_valid_member_id, headers: token_auth_header(user), as: :json
          end.to change(MemberEnrollmentRecord, :count).by(1).
            and change(Member, :count).by(0)

          expect(response).to be_created
          expect(member.reload.membership_number).to be_nil
        end
      end

      it "throws 500 if request has no enrollment_period_id set", use_database_rewinder: true do
        params_with_valid_member_id = params.merge(
          member_id: member.id
        ).except(:enrollment_period_id)

        expect do
          post member_enrollment_records_url, params: params_with_valid_member_id, headers: token_auth_header(user), as: :json
        end.to change(MemberEnrollmentRecord, :count).by(0).
          and change(Member, :count).by(0)

        expect(response).to have_http_status(422)
      end
    end

    context 'member does not exist yet for the member enrollment record' do
      it "creates a member enrollment record", use_database_rewinder: true do
        params_with_non_persisted_member_id = params.merge(
          member_id: build(:member).id
        )
        expect do
          post member_enrollment_records_url, params: params_with_non_persisted_member_id, headers: token_auth_header(user), as: :json
        end.to change(MemberEnrollmentRecord, :count).by(0).
          and change(Member, :count).by(0)

        expect(response).to have_http_status(422)
      end
    end
  end
end
