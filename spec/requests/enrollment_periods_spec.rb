require 'rails_helper'

RSpec.describe "Enrollment Periods", type: :request do
  describe "GET /enrollment_periods" do
    context "as a non-enrollment user" do
      it "returns all enrollment periods" do
        create(:enrollment_period)
        create(:enrollment_period, :in_progress)

        get enrollment_periods_url, headers: token_auth_header, as: :json

        expect(response).to be_successful
        expect(json.size).to eq 2
        expect(json.first.keys).to match_array(%w[
          id
          administrative_division_id
          start_date
          end_date
          coverage_start_date
          coverage_end_date
        ])
      end
    end

    context "as an enrollment user" do
      let!(:top_node) { create(:administrative_division)}
      let!(:region1) { create(:administrative_division, parent: top_node) }
      let!(:region2) { create(:administrative_division, parent: top_node) }
      let!(:subregion1) { create(:administrative_division, parent: region1) }
      let!(:subregion2) { create(:administrative_division, parent: region1) }
      let!(:subregion3) { create(:administrative_division, parent: region2) }
      let!(:subregion4) { create(:administrative_division, parent: region2) }

      let!(:ep0) { create(:enrollment_period, administrative_division: top_node)}
      let!(:ep1) { create(:enrollment_period, administrative_division: region1) }
      let!(:ep2) { create(:enrollment_period, :in_progress, administrative_division: region1) }
      let!(:ep3) { create(:enrollment_period, administrative_division: region2) }
      let!(:ep4) { create(:enrollment_period, :in_progress, administrative_division: region2) }
      let!(:ep5) { create(:enrollment_period, administrative_division: subregion1) }

      let(:enrollment_worker_region1) { create(:user, :enrollment, administrative_division: region1) }
      let(:enrollment_worker_region2) { create(:user, :enrollment, administrative_division: region2) }
      let(:enrollment_worker_subregion1) { create(:user, :enrollment, administrative_division: subregion1) }
      let(:enrollment_worker_subregion2) { create(:user, :enrollment, administrative_division: subregion2) }
      let(:enrollment_worker_subregion3) { create(:user, :enrollment, administrative_division: subregion3) }
      let(:enrollment_worker_subregion4) { create(:user, :enrollment, administrative_division: subregion4) }

      before do
        get enrollment_periods_url, headers: token_auth_header(user), as: :json
      end

      context "user is from sub-region 1" do
        let(:user) { enrollment_worker_subregion1 }

        it "should return enrollment periods that user should have access to" do
          expect(response).to be_successful
          expect(json.size).to eq 4
          expect(json.map { |enrollment_period_json_object| enrollment_period_json_object["id"] }).to match_array(
            [ep0.id, ep1.id, ep2.id, ep5.id]
          )
        end
      end

      context "user is from sub-region 2" do
        let(:user) { enrollment_worker_subregion2 }

        it "should return enrollment periods that user should have access to" do
          expect(response).to be_successful
          expect(json.size).to eq 3
          expect(json.map { |enrollment_period_json_object| enrollment_period_json_object["id"] }).to match_array(
            [ep0.id, ep1.id, ep2.id]
          )
        end
      end

      context "user is from sub-region 3" do
        let(:user) { enrollment_worker_subregion3 }

        it "should return enrollment periods that user should have access to" do
          expect(response).to be_successful
          expect(json.size).to eq 3
          expect(json.map { |enrollment_period_json_object| enrollment_period_json_object["id"] }).to match_array(
            [ep0.id, ep3.id, ep4.id]
          )
        end
      end

      context "user is from sub-region 4" do
        let(:user) { enrollment_worker_subregion4 }

        it "should return enrollment periods that user should have access to" do
          expect(response).to be_successful
          expect(json.size).to eq 3
          expect(json.map { |enrollment_period_json_object| enrollment_period_json_object["id"] }).to match_array(
            [ep0.id, ep3.id, ep4.id]
          )
        end
      end

      context "user is from region 1" do
        let(:user) { enrollment_worker_region1 }

        it "should return enrollment periods that user should have access to" do
          expect(response).to be_successful
          expect(json.size).to eq 4
          expect(json.map { |enrollment_period_json_object| enrollment_period_json_object["id"] }).to match_array(
            [ep0.id, ep1.id, ep2.id, ep5.id]
          )
        end
      end

      context "user is from region 2" do
        let(:user) { enrollment_worker_region2 }

        it "should return enrollment periods that user should have access to" do
          expect(response).to be_successful
          expect(json.size).to eq 3
          expect(json.map { |enrollment_period_json_object| enrollment_period_json_object["id"] }).to match_array(
            [ep0.id, ep3.id, ep4.id]
          )
        end
      end
    end
  end
end
