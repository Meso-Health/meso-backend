require 'rails_helper'

RSpec.describe 'Claims', type: :request do
  let(:admin) { create(:user, :payer_admin) }

  describe 'GET /claims' do
    shared_examples 'returns empty page' do
      it 'returns an empty page with no results' do
        expect(response).to be_successful
        expect(json.fetch('total')).to eq 0
        expect(json.fetch('prev_url')).to be_falsey
        expect(json.fetch('next_url')).to be_falsey
        expect(json.fetch('claims').size).to eq 0
      end
    end

    describe 'standard pagination flow' do
      let(:provider1) { create(:provider) }
      let(:provider2) { create(:provider) }
      let(:provider3) { create(:provider) }
      let(:page_size) { 5 }
      let(:sort_direction) { 'desc' }

      let(:expected_claim_ids) do
        Encounter.where(provider: provider1, adjudication_state: 'pending').sort_by_field('submitted_at', sort_direction).pluck(:claim_id)
      end
      let(:expected_paged_claim_ids) { expected_claim_ids[0..4] }
      let(:expected_paged_claims) do
        Encounter::Claim.sort_by_field(
          Encounter.to_claims(Encounter.where(claim_id: expected_paged_claim_ids)),
          'submitted_at',
          sort_direction
        )
      end

      before do
        [provider1, provider2].each do |p|
          # chain size: 1 (submitted)
          create_list(:encounter, 5, :pending, provider: p)
          create_list(:encounter, 3, :approved, provider: p)
          create_list(:encounter, 3, :rejected, provider: p)

          # chain size: 1 (not submitted)
          create_list(:encounter, 3, :started, provider: p)
          create_list(:encounter, 3, :prepared, provider: p)
          create_list(:encounter, 3, :needs_revision, provider: p)

          # chain size: 2
          5.times do
            create(:encounter, :resubmission, :pending, revised_encounter: create(:encounter, :returned, provider: p))
          end
          3.times do
            create(:encounter, :resubmission, :approved, revised_encounter: create(:encounter, :returned, provider: p))
          end
          3.times do
            create(:encounter, :resubmission, :rejected, revised_encounter: create(:encounter, :returned, provider: p))
          end

          # chain size: 3
          create(:encounter, :resubmission, :pending, revised_encounter:
            create(:encounter, :resubmission, :returned, revised_encounter:
              create(:encounter, :returned, provider: p)))
        end
      end

      shared_examples 'returns correct pages of claims' do
        it 'returns the first page' do
          expect(response).to be_successful
          expect(json.fetch('total')).to eq 11
          expect(json.fetch('prev_url')).to be_falsey
          expect(json.fetch('next_url')).to be_truthy
          expect(json.fetch('claims').size).to eq 5

          expect(json.fetch('claims').map { |x| x['id'] }).to eq(expected_paged_claim_ids)
          expect(json.fetch('claims').map { |x| x['last_submitted_at'] }).to match_timestamp_array(expected_paged_claims.map(&:last_submitted_at))
          expect(json.fetch('claims').map { |x| x['encounters'].map { |x| x['id'] } }).to eq(expected_paged_claims.map { |x| x.encounters.map(&:id) })
        end

        context 'next page' do
          let(:expected_paged_claim_ids) { expected_claim_ids[5..9] }

          before do
            get json.fetch('next_url'), headers: token_auth_header(admin), as: :json
          end

          it 'returns the second page' do
            expect(response).to be_successful
            expect(json.fetch('total')).to eq 11
            expect(json.fetch('prev_url')).to be_truthy
            expect(json.fetch('next_url')).to be_truthy
            expect(json.fetch('claims').size).to eq 5

            expect(json.fetch('claims').map { |x| x['id'] }).to eq(expected_paged_claim_ids)
            expect(json.fetch('claims').map { |x| x['last_submitted_at'] }).to match_timestamp_array(expected_paged_claims.map(&:last_submitted_at))
            expect(json.fetch('claims').map { |x| x['encounters'].map { |x| x['id'] } }).to eq(expected_paged_claims.map { |x| x.encounters.map(&:id) })
          end

          context 'prev page' do
            let(:expected_paged_claim_ids) { expected_claim_ids[0..4] }

            before do
              get json.fetch('prev_url'), headers: token_auth_header(admin), as: :json
            end

            it 'returns the first page' do
              expect(response).to be_successful
              expect(json.fetch('total')).to eq 11
              expect(json.fetch('prev_url')).to be_falsey
              expect(json.fetch('next_url')).to be_truthy
              expect(json.fetch('claims').size).to eq 5

              expect(json.fetch('claims').map { |x| x['id'] }).to eq(expected_paged_claim_ids)
              expect(json.fetch('claims').map { |x| x['last_submitted_at'] }).to match_timestamp_array(expected_paged_claims.map(&:last_submitted_at))
              expect(json.fetch('claims').map { |x| x['encounters'].map { |x| x['id'] } }).to eq(expected_paged_claims.map { |x| x.encounters.map(&:id) })
            end
          end

          context 'next page' do
            let(:expected_paged_claim_ids) { expected_claim_ids[10..10] }

            before do
              get json.fetch('next_url'), headers: token_auth_header(admin), as: :json
            end

            it 'returns the third page' do
              expect(response).to be_successful
              expect(json.fetch('total')).to eq 11
              expect(json.fetch('prev_url')).to be_truthy
              expect(json.fetch('next_url')).to be_falsey
              expect(json.fetch('claims').size).to eq 1

              expect(json.fetch('claims').map { |x| x['id'] }).to eq(expected_paged_claim_ids)
              expect(json.fetch('claims').map { |x| x['last_submitted_at'] }).to match_timestamp_array(expected_paged_claims.map(&:last_submitted_at))
              expect(json.fetch('claims').map { |x| x['encounters'].map { |x| x['id'] } }).to eq(expected_paged_claims.map { |x| x.encounters.map(&:id) })
            end
          end
        end
      end

      context 'default order' do
        before do
          get claims_url(provider_id: provider1.id, limit: page_size, adjudication_state: 'pending'), headers: token_auth_header(admin), as: :json
        end

        it_behaves_like 'returns correct pages of claims'
      end

      context 'reverse order' do
        let(:sort_direction) { 'asc' }

        before do
          get claims_url(provider_id: provider1.id, limit: page_size, adjudication_state: 'pending', sort: 'submitted_at'), headers: token_auth_header(admin), as: :json
        end

        it_behaves_like 'returns correct pages of claims'
      end
    end

    describe 'filtering' do
      describe 'provider id' do
        let(:provider1) { create(:provider) }
        let(:provider2) { create(:provider) }
        let!(:encounter1) { create(:encounter, provider: provider1) }
        let!(:encounter2) { create(:encounter, provider: provider1) }
        let!(:encounter3) { create(:encounter, provider: provider2) }

        context 'no provider id is specified' do
          before do
            get claims_url, headers: token_auth_header(admin), as: :json
          end

          it 'returns claims for all providers' do
            expect(response).to be_successful
            expect(json.fetch('total')).to eq 3
            expect(json.fetch('claims').map { |x| x.fetch('id') }).to match_array [encounter1, encounter2, encounter3].map(&:claim_id)
          end
        end

        context 'valid provider id is specified' do
          before do
            get claims_url(provider_id: provider1.id), headers: token_auth_header(admin), as: :json
          end

          it 'returns only claims for that provider' do
            expect(response).to be_successful
            expect(json.fetch('total')).to eq 2
            expect(json.fetch('claims').map { |x| x.fetch('id') }).to match_array [encounter1, encounter2].map(&:claim_id)
          end
        end

        context 'invalid provider id is specified' do
          before do
            get claims_url(provider_id: 'foobar'), headers: token_auth_header(admin), as: :json
          end

          it 'returns not found' do
            expect(response).to be_not_found
          end
        end

        context 'user is provider user requesting same provider_id' do
          let(:provider_user) { create(:user, :provider_admin, provider: provider1 )}

          before do
            get claims_url(provider_id: provider1.id), headers: token_auth_header(provider_user), as: :json
          end

          it 'returns claims from that provider' do
            expect(response).to be_successful
            expect(json.fetch('total')).to eq 2
            expect(json.fetch('claims').map { |x| x.fetch('id') }).to match_array [encounter1, encounter2].map(&:claim_id)
          end
        end

        context 'user is provider user requesting different provider_id' do
          let(:provider_user) { create(:user, :provider_admin, provider: provider1 )}

          before do
            get claims_url(provider_id: provider2.id), headers: token_auth_header(provider_user), as: :json
          end

          it 'returns forbidden' do
            expect(response).to be_forbidden
          end
        end
      end

      describe 'provider type' do
        let(:provider1) { create(:provider, provider_type: 'health_center') }
        let(:provider2) { create(:provider, provider_type: 'health_center') }
        let(:provider3) { create(:provider, provider_type: 'general_hospital') }
        let!(:encounter1) { create(:encounter, provider: provider1) }
        let!(:encounter2) { create(:encounter, provider: provider2) }
        let!(:encounter3) { create(:encounter, provider: provider3) }

        context 'no provider type is specified' do
          before do
            get claims_url, headers: token_auth_header(admin), as: :json
          end

          it 'returns claims for all providers' do
            expect(response).to be_successful
            expect(json.fetch('total')).to eq 3
            expect(json.fetch('claims').map { |x| x.fetch('id') }).to match_array [encounter1, encounter2, encounter3].map(&:claim_id)
          end
        end

        context 'valid provider type is specified' do
          before do
            get claims_url(provider_type: 'health_center'), headers: token_auth_header(admin), as: :json
          end

          it 'returns only claims for that provider type' do
            expect(response).to be_successful
            expect(json.fetch('total')).to eq 2
            expect(json.fetch('claims').map { |x| x.fetch('id') }).to match_array [encounter1, encounter2].map(&:claim_id)
          end
        end

        context 'invalid provider type is specified' do
          before do
            get claims_url(provider_type: 'foobar'), headers: token_auth_header(admin), as: :json
          end

          it_behaves_like 'returns empty page'
        end
      end

      describe 'returned_to_preparer' do
        let(:provider1) { create(:provider) }
        let(:provider2) { create(:provider) }
        let(:provider_user) { create(:user, :submission, provider: provider1 ) }
        let!(:encounter1) { create(:encounter, :returned, provider: provider1) }
        let!(:encounter2) { create(:encounter, :needs_revision, provider: provider1) }
        let!(:encounter3) { create(:encounter, :approved, provider: provider1) }
        let!(:encounter4) { create(:encounter, provider: provider2) }

        context "when the request is valid" do
          before do
            get claims_url(returned_to_preparer: true, sort: 'occurred_at'), headers: token_auth_header(provider_user), as: :json
          end

          it "should return returned claims" do
            expect(response).to be_successful
            expect(json.fetch('total')).to eq 2
            expect(json.fetch('claims').map { |x| x.fetch('id') }).to match_array [encounter1, encounter2].map(&:claim_id)
          end
        end
      end

      describe 'member admin division' do
        let(:admin_division_1) { create(:administrative_division, level: 'second') }
        let(:admin_division_2) { create(:administrative_division, level: 'second') }
        let(:admin_division_3) { create(:administrative_division, level: 'third', parent: admin_division_1) }
        let(:admin_division_4) { create(:administrative_division, level: 'third', parent: admin_division_1) }
        let(:admin_division_5) { create(:administrative_division, level: 'third', parent: admin_division_2) }
        let(:household1) { create(:household, administrative_division: admin_division_3) }
        let(:household2) { create(:household, administrative_division: admin_division_4) }
        let(:household3) { create(:household, administrative_division: admin_division_5) }
        let(:member1) { create(:member, household: household1) }
        let(:member2) { create(:member, household: household2) }
        let(:member3) { create(:member, household: household3) }
        let!(:encounter1) { create(:encounter, member: member1) }
        let!(:encounter2) { create(:encounter, member: member2) }
        let!(:encounter3) { create(:encounter, member: member3) }

        context 'no member admin division is specified' do
          before do
            get claims_url, headers: token_auth_header(admin), as: :json
          end

          it 'returns claims for all member admin divisions' do
            expect(response).to be_successful
            expect(json.fetch('total')).to eq 3
            expect(json.fetch('claims').map { |x| x.fetch('id') }).to match_array [encounter1, encounter2, encounter3].map(&:claim_id)
          end
        end

        context 'valid member admin division is specified' do
          before do
            get claims_url(member_admin_division_id: admin_division_1.id), headers: token_auth_header(admin), as: :json
          end

          it 'returns only claims for that provider type' do
            expect(response).to be_successful
            expect(json.fetch('total')).to eq 2
            expect(json.fetch('claims').map { |x| x.fetch('id') }).to match_array [encounter1, encounter2].map(&:claim_id)
          end
        end

        context 'invalid member admin division is specified' do
          before do
            get claims_url(member_admin_division_id: 'foobar'), headers: token_auth_header(admin), as: :json
          end

          it 'returns not found' do
            expect(response).to be_not_found
          end
        end
      end

      describe 'min and max reimbursal amount' do
        let!(:encounter1) { create(:encounter, :with_items, price: 0) }
        let!(:encounter2) { create(:encounter, :with_items, price: 2000) }
        let!(:encounter3) { create(:encounter, :with_items, price: 5000) }
        let!(:encounter4) { create(:encounter, :with_items, price: 5000) }
        let!(:encounter5) { create(:encounter, :with_items, price: 8000) }

        context 'neither specified' do
          before do
            get claims_url, headers: token_auth_header(admin), as: :json
          end

          it 'returns claims with any amount' do
            expect(response).to be_successful
            expect(json.fetch('total')).to eq 5
            expect(json.fetch('claims').map { |x| x.fetch('id') }).to match_array [encounter1, encounter2, encounter3, encounter4, encounter5].map(&:claim_id)
          end
        end

        context 'valid min amount specified' do
          before do
            get claims_url(min_amount: 2500), headers: token_auth_header(admin), as: :json
          end

          it 'returns claims greater than the min amount' do
            expect(response).to be_successful
            expect(json.fetch('total')).to eq 3
            expect(json.fetch('claims').map { |x| x.fetch('id') }).to match_array [encounter3, encounter4, encounter5].map(&:claim_id)
          end
        end

        context 'valid max amount specified' do
          before do
            get claims_url(max_amount: 5000), headers: token_auth_header(admin), as: :json
          end

          it 'returns claims less than the max amount' do
            expect(response).to be_successful
            expect(json.fetch('total')).to eq 4
            expect(json.fetch('claims').map { |x| x.fetch('id') }).to match_array [encounter1, encounter2, encounter3, encounter4].map(&:claim_id)
          end
        end

        context 'valid min and max amount specified' do
          before do
            get claims_url(min_amount: 2500, max_amount: 5000), headers: token_auth_header(admin), as: :json
          end

          it 'returns claims between the min and max amounts' do
            expect(response).to be_successful
            expect(json.fetch('total')).to eq 2
            expect(json.fetch('claims').map { |x| x.fetch('id') }).to match_array [encounter3, encounter4].map(&:claim_id)
          end
        end

        context 'invalid min or max amount specified' do
          before do
            get claims_url(min_amount: 5000, max_amount: 'foobar'), headers: token_auth_header(admin), as: :json
          end

          it 'returns bad request' do
            expect(response).to be_bad_request
          end
        end
      end

      describe 'submitted_at start date and end date' do
        let!(:encounter1) { create(:encounter, submitted_at: Time.zone.parse('2017/03/15 EAT')) }
        let!(:encounter2) { create(:encounter, submitted_at: Time.zone.parse('2018/03/17 EAT')) }
        let!(:encounter3) { create(:encounter, submitted_at: Time.zone.parse('2018/03/17 EAT')) }
        let!(:encounter4) { create(:encounter, submitted_at: Time.zone.parse('2019/01/01 EAT')) }

        context 'neither specified' do
          before do
            get claims_url, headers: token_auth_header(admin), as: :json
          end

          it 'returns claims with submitted_at' do
            expect(response).to be_successful
            expect(json.fetch('total')).to eq 4
            expect(json.fetch('claims').map { |x| x.fetch('id') }).to match_array [encounter1, encounter2, encounter3, encounter4].map(&:claim_id)
          end
        end

        context 'valid start date specified' do
          before do
            get claims_url(start_date: '2017/03/17 EAT'), headers: token_auth_header(admin), as: :json
          end

          it 'returns claims after the start date' do
            expect(response).to be_successful
            expect(json.fetch('total')).to eq 3
            expect(json.fetch('claims').map { |x| x.fetch('id') }).to match_array [encounter2, encounter3, encounter4].map(&:claim_id)
          end
        end

        context 'valid end date specified' do
          before do
            get claims_url(end_date: '2018/12/31 EAT'), headers: token_auth_header(admin), as: :json
          end

          it 'returns claims before the end date' do
            expect(response).to be_successful
            expect(json.fetch('total')).to eq 3
            expect(json.fetch('claims').map { |x| x.fetch('id') }).to match_array [encounter1, encounter2, encounter3].map(&:claim_id)
          end
        end

        context 'valid start and end dates specified' do
          before do
            get claims_url(start_date: '2017/03/17 EAT', end_date: '2018/12/31 EAT'), headers: token_auth_header(admin), as: :json
          end

          it 'returns claims between the start and end dates' do
            expect(response).to be_successful
            expect(json.fetch('total')).to eq 2
            expect(json.fetch('claims').map { |x| x.fetch('id') }).to match_array [encounter2, encounter3].map(&:claim_id)
          end
        end

        context 'invalid start or end date specified' do
          before do
            get claims_url(start_date: '2017/03/16 EAT', end_date: 88888888), headers: token_auth_header(admin), as: :json
          end

          it 'returns bad request' do
            expect(response).to be_bad_request
          end
        end
      end

      describe 'adjudication state' do
        let!(:encounter1) { create(:encounter, :started) }
        let!(:encounter2) { create(:encounter, :pending) }
        let!(:encounter3) { create(:encounter, :approved) }
        let!(:encounter4) { create(:encounter, :rejected) }
        let!(:encounter5) { create(:encounter, :returned) }
        let!(:encounter6) { create(:encounter, :resubmission, :pending, revised_encounter: create(:encounter, :returned)) }
        let!(:encounter7) { create(:encounter, :resubmission, :approved, revised_encounter: create(:encounter, :returned)) }
        let!(:encounter8) { create(:encounter, :resubmission, :rejected, revised_encounter: create(:encounter, :returned)) }
        let!(:encounter9) { create(:encounter, :resubmission, :returned, revised_encounter: create(:encounter, :returned)) }

        context 'no adjudication state is specified' do
          before do
            get claims_url, headers: token_auth_header(admin), as: :json
          end

          it 'returns all submitted claims' do
            expect(response).to be_successful
            expect(json.fetch('total')).to eq 8
            expect(json.fetch('claims').map { |x| x.fetch('id') })
              .to match_array [encounter2, encounter3, encounter4, encounter5, encounter6, encounter7, encounter8, encounter9].map(&:claim_id)
          end
        end

        context 'valid adjudication state is specified' do
          before do
            get claims_url(adjudication_state: 'approved'), headers: token_auth_header(admin), as: :json
          end

          it 'returns only claims with that adjudication state' do
            expect(response).to be_successful
            expect(json.fetch('total')).to eq 2
            expect(json.fetch('claims').map { |x| x.fetch('id') }).to match_array [encounter3, encounter7].map(&:claim_id)
          end
        end

        context 'invalid adjudication state is specified' do
          before do
            get claims_url(adjudication_state: 'foobar'), headers: token_auth_header(admin), as: :json
          end

          it 'returns bad request' do
            expect(response).to be_bad_request
          end
        end
      end

      describe 'submission state' do
        let!(:encounter1) { create(:encounter, :started) }
        let!(:encounter2) { create(:encounter, :pending) }
        let!(:encounter3) { create(:encounter, :approved) }
        let!(:encounter4) { create(:encounter, :rejected) }
        let!(:encounter5) { create(:encounter, :returned) }
        let!(:encounter6) { create(:encounter, :resubmission, :started, revised_encounter: create(:encounter, :returned)) }
        let!(:encounter7) { create(:encounter, :resubmission, :pending, revised_encounter: create(:encounter, :returned)) }
        let!(:encounter8) { create(:encounter, :resubmission, :approved, revised_encounter: create(:encounter, :returned)) }
        let!(:encounter9) { create(:encounter, :resubmission, :rejected, revised_encounter: create(:encounter, :returned)) }
        let!(:encounter10) { create(:encounter, :resubmission, :returned, revised_encounter: create(:encounter, :returned)) }

        context 'no submission state is specified' do
          before do
            get claims_url, headers: token_auth_header(admin), as: :json
          end

          it 'returns all submitted claims' do
            expect(response).to be_successful
            expect(json.fetch('total')).to eq 8
            expect(json.fetch('claims').map { |x| x.fetch('id') })
              .to match_array [encounter2, encounter3, encounter4, encounter5, encounter7, encounter8, encounter9, encounter10].map(&:claim_id)
          end
        end

        context 'valid submission state is specified' do
          before do
            get claims_url(submission_state: 'started', sort: 'occurred_at'), headers: token_auth_header(admin), as: :json
          end

          it 'returns only claims with that submission state' do
            expect(response).to be_successful
            expect(json.fetch('total')).to eq 2
            expect(json.fetch('claims').map { |x| x.fetch('id') }).to match_array [encounter1, encounter6].map(&:claim_id)
          end
        end

        context 'invalid submission state is specified' do
          before do
            get claims_url(submission_state: 'foobar'), headers: token_auth_header(admin), as: :json
          end

          it 'returns bad request' do
            expect(response).to be_bad_request
          end
        end
      end

      describe 'resubmitted' do
        let!(:encounter1) { create(:encounter) }
        let!(:encounter2) { create(:encounter, :resubmission, revised_encounter: create(:encounter, :returned)) }

        context 'not specified' do
          before do
            get claims_url, headers: token_auth_header(admin), as: :json
          end

          it 'returns all claims' do
            expect(response).to be_successful
            expect(json.fetch('total')).to eq 2
            expect(json.fetch('claims').map { |x| x.fetch('id') }).to match_array [encounter1, encounter2].map(&:claim_id)
          end
        end

        context 'specified to be true' do
          before do
            get claims_url(resubmitted: 'true'), headers: token_auth_header(admin), as: :json
          end

          it 'returns only claims that have been resubmitted' do
            expect(response).to be_successful
            expect(json.fetch('total')).to eq 1
            expect(json.fetch('claims').map { |x| x.fetch('id') }).to match_array [encounter2].map(&:claim_id)
          end
        end

        context 'specified to be false' do
          before do
            get claims_url(resubmitted: 'false'), headers: token_auth_header(admin), as: :json
          end

          it 'returns only claims that have not been resubmitted' do
            expect(response).to be_successful
            expect(json.fetch('total')).to eq 1
            expect(json.fetch('claims').map { |x| x.fetch('id') }).to match_array [encounter1].map(&:claim_id)
          end
        end
      end

      describe 'audited' do
        let!(:encounter1) { create(:encounter) }
        let!(:encounter2) { create(:encounter, :audited) }

        context 'not specified' do
          before do
            get claims_url, headers: token_auth_header(admin), as: :json
          end

          it 'returns all claims' do
            expect(response).to be_successful
            expect(json.fetch('total')).to eq 2
            expect(json.fetch('claims').map { |x| x.fetch('id') }).to match_array [encounter1, encounter2].map(&:claim_id)
          end
        end

        context 'specified to be true' do
          before do
            get claims_url(audited: 'true'), headers: token_auth_header(admin), as: :json
          end

          it 'returns only claims that have been audited' do
            expect(response).to be_successful
            expect(json.fetch('total')).to eq 1
            expect(json.fetch('claims').map { |x| x.fetch('id') }).to match_array [encounter2].map(&:claim_id)
          end
        end

        context 'specified to be false' do
          before do
            get claims_url(audited: 'false'), headers: token_auth_header(admin), as: :json
          end

          it 'returns only claims that have not been audited' do
            expect(response).to be_successful
            expect(json.fetch('total')).to eq 1
            expect(json.fetch('claims').map { |x| x.fetch('id') }).to match_array [encounter1].map(&:claim_id)
          end
        end
      end

      describe 'paid' do
        let!(:encounter1) { create(:encounter) }
        let!(:encounter2) { create(:encounter, :reimbursed) }

        context 'not specified' do
          before do
            get claims_url, headers: token_auth_header(admin), as: :json
          end

          it 'returns all claims' do
            expect(response).to be_successful
            expect(json.fetch('total')).to eq 2
            expect(json.fetch('claims').map { |x| x.fetch('id') }).to match_array [encounter1, encounter2].map(&:claim_id)
          end
        end

        context 'specified to be true' do
          before do
            get claims_url(paid: 'true'), headers: token_auth_header(admin), as: :json
          end

          it 'returns only claims that have been paid' do
            expect(response).to be_successful
            expect(json.fetch('total')).to eq 1
            expect(json.fetch('claims').map { |x| x.fetch('id') }).to match_array [encounter2].map(&:claim_id)
          end
        end

        context 'specified to be false' do
          before do
            get claims_url(paid: 'false'), headers: token_auth_header(admin), as: :json
          end

          it 'returns only claims that have not been paid' do
            expect(response).to be_successful
            expect(json.fetch('total')).to eq 1
            expect(json.fetch('claims').map { |x| x.fetch('id') }).to match_array [encounter1].map(&:claim_id)
          end
        end
      end

      describe 'flag' do
        let!(:encounter1) { create(:encounter) }
        let!(:encounter2) { create(:encounter, member: create(:member, :unconfirmed)) }

        context 'not specified' do
          before do
            get claims_url, headers: token_auth_header(admin), as: :json
          end

          it 'returns all claims' do
            expect(response).to be_successful
            expect(json.fetch('total')).to eq 2
            expect(json.fetch('claims').map { |x| x.fetch('id') }).to match_array [encounter1, encounter2].map(&:claim_id)
          end
        end

        context 'valid flag is specified' do
          before do
            get claims_url(flag: 'unconfirmed_member'), headers: token_auth_header(admin), as: :json
          end

          it 'returns only claims that match the flag' do
            expect(response).to be_successful
            expect(json.fetch('total')).to eq 1
            expect(json.fetch('claims').map { |x| x.fetch('id') }).to match_array [encounter2].map(&:claim_id)
          end
        end

        context 'invalid flag is specified' do
          before do
            get claims_url(flag: 'foo'), headers: token_auth_header(admin), as: :json
          end

          it 'returns bad request' do
            expect(response).to be_bad_request
          end
        end
      end
    end

    describe 'searching' do
      context 'neither search field nor search query are specified' do
        before do
          get claims_url, headers: token_auth_header(admin), as: :json
        end

        it 'returns a successful response of results not filtered by search query' do
          expect(response).to be_successful
        end
      end

      context 'search field is specified but not search query' do
        before do
          get claims_url(search_field: 'claim_id'), headers: token_auth_header(admin), as: :json
        end

        it 'returns bad request' do
          expect(response).to be_bad_request
        end
      end

      context 'search query is specified but not search field' do
        before do
          get claims_url(search_query: '12345'), headers: token_auth_header(admin), as: :json
        end

        it 'returns bad request' do
          expect(response).to be_bad_request
        end
      end

      context 'both search field and search query are specified' do
        describe 'searching by claim id' do
          # claim_id is same as id for first encounters of a claim
          let!(:encounter1) { create(:encounter, id: '02382d96-a40e-49a4-9594-01a7a257ac4d') }
          let!(:encounter2) { create(:encounter, id: '02382d96-6682-4678-be3c-8cede6b5359e') }

          context 'query does not match any claims' do
            before do
              get claims_url(search_field: 'claim_id', search_query: 'FOOBAR!!'), headers: token_auth_header(admin), as: :json
            end

            it_behaves_like 'returns empty page'
          end

          context 'query matches claims' do
            before do
              get claims_url(search_field: 'claim_id', search_query: '02382D96'), headers: token_auth_header(admin), as: :json
            end

            it 'returns all matching claims' do
              expect(response).to be_successful
              expect(json.fetch('total')).to eq 2
              expect(json.fetch('claims').map { |x| x.fetch('id') }).to match_array [encounter1, encounter2].map(&:claim_id)
            end
          end
        end

        describe 'searching by membership number' do
          let(:household) { create(:household) }
          let(:member1) { create(:member, household: household, membership_number: '123456') }
          let(:member2) { create(:member, household: household, membership_number: '987654') }
          let!(:encounter1) { create(:encounter, member: member1) }
          let!(:encounter2) { create(:encounter, member: member1) }
          let!(:encounter3) { create(:encounter, member: member2) }

          context 'query does not match any claims' do
            before do
              get claims_url(search_field: 'membership_number', search_query: '999999'), headers: token_auth_header(admin), as: :json
            end

            it_behaves_like 'returns empty page'
          end

          context 'member membership number is passed as query' do
            before do
              get claims_url(search_field: 'membership_number', search_query: '123456'), headers: token_auth_header(admin), as: :json
            end

            it 'returns all claims for that member' do
              expect(response).to be_successful
              expect(json.fetch('total')).to eq 2
              expect(json.fetch('claims').map { |x| x.fetch('id') }).to match_array [encounter1, encounter2].map(&:claim_id)
            end
          end
        end
      end
    end
  end

  describe 'GET /claims.csv' do
    before do
      get claims_url(format: :csv), headers: token_auth_header(admin)
    end

    it 'is successful' do
      expect(response).to be_successful
    end
  end

  describe 'GET /claims/:encounter_id' do
    let(:encounter1) { create(:encounter, :returned) }
    let(:encounter2) { create(:encounter, :resubmission, revised_encounter: encounter1) }
    let!(:claim) { Encounter::Claim.new(id: encounter1.claim_id, encounters: [encounter1, encounter2]) }

    before do
      get claim_url(encounter_id), headers: token_auth_header(admin), as: :json
    end

    context 'encounter_id does not match any encounters' do
      let(:encounter_id) { 'foobar' }

      it 'returns a 404 not found' do
        expect(response).to be_not_found
      end
    end

    context 'encounter_id matches first encounter of a claim' do
      let(:encounter_id) { encounter1.id }

      it 'returns the full claim' do
        expect(response).to be_successful
        expect(json.fetch('id')).to eq claim.id
        expect(json.fetch('last_submitted_at')).to match_timestamp claim.last_submitted_at
        expect(json.fetch('encounters').map { |x| x.fetch('id') }).to match_array [encounter1.id, encounter2.id]
      end
    end

    context 'encounter_id matches last encounter of a claim' do
      let(:encounter_id) { encounter2.id }

      it 'returns the full claim' do
        expect(response).to be_successful
        expect(json.fetch('id')).to eq claim.id
        expect(json.fetch('last_submitted_at')).to match_timestamp claim.last_submitted_at
        expect(json.fetch('encounters').map { |x| x.fetch('id') }).to match_array [encounter1.id, encounter2.id]
      end
    end
  end

  describe 'GET /member/:id/claims' do
    let(:member) { create(:member) }
    start_date = 200.days.ago
    end_date = 10.day.ago

    before do
      # before start_date
      create_list(:encounter, 3, submitted_at: 201.days.ago, member_id: member.id)
      # between start_date and end_date
      create_list(:encounter, 3, submitted_at: 100.days.ago, member_id: member.id)
      # after end_date
      create_list(:encounter, 3, submitted_at: 9.days.ago, member_id: member.id)

      # chain size: 2, original submission before start_date resubmission after
      create(:encounter, :resubmission, :approved, prepared_at: 101.days.ago, submitted_at: 100.days.ago, member_id: member.id, revised_encounter: create(:encounter, prepared_at: 202.days.ago, submitted_at: 201.days.ago, member_id: member.id))

      # chain size: 2, original submission and resubmission before start_date
      create(:encounter, :resubmission, :approved, prepared_at: 202.days.ago, submitted_at: 201.days.ago, member_id: member.id, revised_encounter: create(:encounter, prepared_at: 202.days.ago, submitted_at: 201.days.ago, member_id: member.id))

      # chain size: 2, original submission before end_date and resubmission after end_date
      create(:encounter, :resubmission, :approved, prepared_at: 10.days.ago, submitted_at: 9.days.ago, member_id: member.id, revised_encounter: create(:encounter, prepared_at: 101.days.ago, submitted_at: 100.days.ago, member_id: member.id))
    end

    context 'without start_date and end_date specified' do
      before do
        get "/members/#{member.id}/claims", headers: token_auth_header(admin), as: :json
      end

      it 'returns a list of all claims' do
        expect(response).to be_successful
        expect(json.size).to eq 12
      end
    end

    context 'with start_date and end_date specified' do
      before do
        get "/members/#{member.id}/claims?start_date=#{start_date}&end_date=#{end_date}", headers: token_auth_header(admin), as: :json
      end

      it 'returns a list of claims submitted between 10 & 200 days ago' do
        expect(response).to be_successful
        expect(json.size).to eq 4
      end
    end

    context 'with ONLY start_date specified' do
      before do
        get "/members/#{member.id}/claims?start_date=#{start_date}", headers: token_auth_header(admin), as: :json
      end

      it 'returns a list of claims submitted less than 200 days ago' do
        expect(response).to be_successful
        expect(json.size).to eq 8
      end
    end

    context 'with ONLY end_date specified' do
      before do
        get "/members/#{member.id}/claims?end_date=#{end_date}", headers: token_auth_header(admin), as: :json
      end

      it 'returns a list of claims submitted more than 10 days ago' do
        expect(response).to be_successful
        expect(json.size).to eq 8
      end
    end
  end
end
