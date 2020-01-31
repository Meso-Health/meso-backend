require 'rails_helper'

RSpec.describe "Provider Members", type: :request do
  let(:readable_member_fields) do
    %w[id household_id created_at updated_at enrolled_at absentee card_id full_name gender age birthdate
       birthdate_accuracy phone_number preferred_language fingerprints_guid photo_url membership_number
       medical_record_number medical_record_numbers profession relationship_to_head archived_at
       archived_reason needs_renewal administrative_division_id unpaid coverage_end_date renewed_at]
  end

  let(:writable_member_fields) do
    %w[id household_id full_name gender card_id phone_number enrolled_at birthdate birthdate_accuracy fingerprints_guid membership_number medical_record_number]
  end

  let!(:enrollment_period) { create(:enrollment_period, :in_progress) }

  # second-level administrative division A
  let(:second_ad_a) { create(:administrative_division, :second) }
  let(:third_ad_aa) { create(:administrative_division, :third, parent: second_ad_a) }
  let(:third_ad_ab) { create(:administrative_division, :third, parent: second_ad_a) }
  # second-level administrative division A: uses and providers
  let(:enrollment_user) { create(:user, :enrollment, administrative_division: third_ad_aa) }
  let(:provider1) { create(:provider, administrative_division: second_ad_a) }
  let(:provider_user1) { create(:user, :provider_admin, provider: provider1) }
  # second-level administrative division A: Household A with 19 members and 1 archived.
  let!(:household1A) { create(:household, :with_members, members_count: 19, administrative_division: third_ad_aa) }
  let!(:household1A_archived_member) { create(:member, :archived, household: household1A) }
  # second-level administrative division A: Household B with 3 members
  let!(:household1B) { create(:household, :with_members, members_count: 3, administrative_division: third_ad_ab) }

  # second-level administrative division B
  let(:second_ad_b) { create(:administrative_division, :second) }
  let(:third_ad_ba) { create(:administrative_division, :third, parent: second_ad_b) }
  # second-level administrative division B: users, and providers
  let(:provider2) { create(:provider, administrative_division: second_ad_b) }
  let(:provider_user2) { create(:user, :provider_admin, provider: provider2) }
  # second-level administrative division B: Household with 8 active members and 1 archived.
  let!(:household2) { create(:household, :with_members, members_count: 8, administrative_division: second_ad_b) }
  let!(:household2_archived_member) { create(:member, :archived, household: household2) }

  describe "GET /members/search" do
    let!(:member_with_mrns1) { create(:member,
      full_name: 'lebron k james ',
      household: household1A,
      medical_record_numbers: {
        "#{provider1.id}": "123456",
        "#{provider2.id}": "654321",
        "primary": "333",
      }
    )}

    before do
      get search_members_url, params: params, headers: token_auth_header(user), as: :json
    end

    context "search by name as provider user" do
      let!(:params) {
        {
          name: 'lebron k jamesz',
          administrative_division_id: third_ad_aa.id,
        }
      }
      let(:user) { provider_user1 }

      it "should return the member" do
        expect(response).to be_successful
        expect(json.size).to eq 1
      end
    end


    context "search by name as non-provider or enrollment user" do
      let!(:params) {
        {
          name: 'lebron k jamesz',
          administrative_division_id: third_ad_aa.id,
        }
      }
      let(:user) { create(:user, :adjudication) }

      it "should return the member" do
        expect(response).to be_successful
        expect(json.size).to eq 1
      end
    end

    context "search by MRN as a provider user" do
      let(:user) { provider_user1 }
      let!(:params) {
        {
          medical_record_number: 123456,
        }
      }

      it "should return the member" do
        expect(response).to be_successful
        expect(json.size).to eq 1
      end
    end

    context "search by MRN as a non-provider or enrollment user" do
      let(:user) { create(:user, :adjudication) }
      let(:params) {
        {
          medical_record_number: 123456,
          provider_id: provider1.id,
        }
      }

      it "should return the member" do
        expect(response).to be_successful
        expect(json.size).to eq 1
      end
    end
  end

  describe "GET /providers/:id/members" do
    let(:page_size) { 10 }
    let(:default_page_size) { 100 }

    context 'medical record number edge cases' do
      # Create a new second-level administrative division, which contains 3 providers.
      let(:second_ad_c) { create(:administrative_division, :second) }
      let(:third_ad_ca) { create(:administrative_division, :third, parent: second_ad_c) }
      let(:provider3) { create(:provider, administrative_division: second_ad_c) }
      let(:provider4) { create(:provider, administrative_division: second_ad_c) }
      let(:provider5) { create(:provider, administrative_division: second_ad_c) }
      let(:provider_user3) { create(:user, :provider_admin, provider: provider3) }
      let(:provider_user4) { create(:user, :provider_admin, provider: provider4) }
      let(:provider_user5) { create(:user, :provider_admin, provider: provider5) }

      # Add a single enrolled member with multiple MRNs.
      let!(:household) { create(:household, administrative_division: third_ad_ca) }
      let!(:member) { create(:member, household: household, medical_record_numbers: {
        "#{provider3.id}": 123,
        "#{provider4.id}": 456,
        "primary": 789
      })}

      context 'if requesting user is from provider 3' do
        before do
          get provider_members_url(provider3), headers: token_auth_header(provider_user3), as: :json
        end

        it 'returns a member with the medical record number from provider 3' do
          expect(response).to be_successful
          expect(json.fetch('members').size).to eq 1
          expect(json.fetch('members').first.fetch('medical_record_number')).to eq 123
        end
      end

      context 'if requesting user is from provider 4' do
        before do
          get provider_members_url(provider4), headers: token_auth_header(provider_user4), as: :json
        end

        it 'returns a member with the medical record number from provider 4' do
          expect(response).to be_successful
          expect(json.fetch('members').size).to eq 1
          expect(json.fetch('members').first.fetch('medical_record_number')).to eq 456
        end
      end

      context 'if requesting user is from provider 5' do
        before do
          get provider_members_url(provider5), headers: token_auth_header(provider_user5), as: :json
        end

        it 'returns a member with no medical record number' do
          expect(response).to be_successful
          expect(json.fetch('members').size).to eq 1
          expect(json.fetch('members').first.fetch('medical_record_number')).to eq nil
        end
      end
    end

    # TODO: move tests for general pagination params to pagination_controller_spec
    context 'parameter edge cases' do
      context 'limit' do
        context 'not specified' do
          before do
            get provider_members_url(provider1), headers: token_auth_header(provider_user1), as: :json
          end

          it 'returns all members that can fit within the default page size' do
            expect(response).to be_successful
            expect(json.fetch('members').size).to eq 23
          end
        end

        context 'negative' do
          before do
            get provider_members_url(provider1, limit: -1), headers: token_auth_header(provider_user1), as: :json
          end

          it 'returns bad request' do
            expect(response).to be_bad_request
          end
        end

        context '0' do
          before do
            get provider_members_url(provider1, limit: 0), headers: token_auth_header(provider_user1), as: :json
          end

          it 'returns bad request' do
            expect(response).to be_bad_request
          end
        end

        context 'larger than the maximum page size' do
          before do
            get provider_members_url(provider1, limit: 10000), headers: token_auth_header(provider_user1), as: :json
          end

          it 'returns bad request' do
            expect(response).to be_bad_request
          end
        end

        context 'not an integer' do
          before do
            get provider_members_url(provider1, limit: 'foo'), headers: token_auth_header(provider_user1), as: :json
          end

          it 'returns bad request' do
            expect(response).to be_bad_request
          end
        end
      end

      context 'page_key' do
        context 'not_specified' do
          before do
            get provider_members_url(provider1, limit: page_size), headers: token_auth_header(provider_user1), as: :json
          end

          it 'starts from the first page' do
            expect(response).to be_successful
            expect(json.fetch('members').size).to eq page_size
          end
        end

        context 'indecipherable' do
          before do
            get provider_members_url(provider1, limit: page_size, page_key: 'asdf'), headers: token_auth_header(provider_user1), as: :json
          end

          it 'returns bad request' do
            expect(response).to be_bad_request
          end
        end

        context 'invalid values' do
          let(:page_key) { { cursor: { created_at: 'foo', cursor_id: 'bar' }, cache_key: nil, next_cache_key: nil } }

          before do
            get provider_members_url(provider1, limit: page_size, page_key: Base64.strict_encode64(page_key.to_json)), headers: token_auth_header, as: :json
          end

          it 'returns bad request' do
            expect(response).to be_bad_request
          end
        end
      end
    end

    context 'if request is from a provider in second-level administrative division A' do
      before do
        get provider_members_url(provider1, limit: page_size), headers: token_auth_header(provider_user1), as: :json
      end

      it 'returns the first page of members for second-level administrative division A' do
        expect(response).to be_successful
        expect(json.fetch('has_more')).to be_truthy
        expect(json.fetch('page_key')).to be_truthy
        expect(json.fetch('members').size).to eq page_size
        expect(json.fetch('members').first.keys).to match_array(readable_member_fields)
      end

      # the same client wouldn't send the same request without a page key; this is more to test a request from a different client
      context 'repeat request without page key' do
        before do
          get provider_members_url(provider1, limit: page_size), headers: token_auth_header(provider_user1), as: :json
        end

        it 'returns the same first page of members for second-level administrative division A' do
          expect(response).to be_successful
          expect(json.fetch('has_more')).to be_truthy
          expect(json.fetch('page_key')).to be_truthy
          expect(json.fetch('members').size).to eq page_size
          expect(json.fetch('members').first.keys).to match_array(readable_member_fields)
        end
      end

      context 'next page request' do
        context 'the remainder of the page requests' do
          before do
            get provider_members_url(provider1, limit: page_size, page_key: json.fetch('page_key')), headers: token_auth_header(provider_user1), as: :json
          end

          it 'returns the second page' do
            expect(response).to be_successful
            expect(json.fetch('has_more')).to be_truthy
            expect(json.fetch('page_key')).to be_truthy
            expect(json.fetch('members').size).to eq 10
            expect(json.fetch('members').first.keys).to match_array(readable_member_fields)
          end

          context 'the third (last) page request' do
            before do
              get provider_members_url(provider1, limit: page_size, page_key: json.fetch('page_key')), headers: token_auth_header(provider_user1), as: :json
            end

            it 'returns the third page' do
              expect(response).to be_successful
              expect(json.fetch('has_more')).to be_falsey
              expect(json.fetch('page_key')).to be_truthy
              expect(json.fetch('members').size).to eq 3
              expect(json.fetch('members').first.keys).to match_array(readable_member_fields)
            end
          end
        end
      end

      context 'next batch request' do
        before do
          get provider_members_url(provider1, limit: default_page_size, page_key: json.fetch('page_key')), headers: token_auth_header(provider_user1), as: :json
        end

        context 'there have been no changes to any members' do
          let(:request_page_key) { json.fetch('page_key') }

          before do
            get provider_members_url(provider1, limit: default_page_size, page_key: request_page_key), headers: token_auth_header(provider_user1), as: :json
          end

          it 'returns an empty page with the same page key' do
            expect(response).to be_successful
            expect(json.fetch('has_more')).to be_falsey
            expect(json.fetch('page_key')).to eq request_page_key
            expect(json.fetch('members')).to eq []
          end
        end

        context 'members in different administrative division have been changed' do
          let(:request_page_key) { json.fetch('page_key') }

          before do
            PaperTrail.without_versioning {
              household2.members.first.update_attributes(full_name: 'bar') # edit member in second_ad_b
              create(:member, household: household2) # add member to second_ad_b
            }
            get provider_members_url(provider1, limit: page_size, page_key: request_page_key), headers: token_auth_header(provider_user1), as: :json
          end

          it 'returns an empty page with the same page key' do
            expect(response).to be_successful
            expect(json.fetch('has_more')).to be_falsey
            expect(json.fetch('page_key')).to eq request_page_key
            expect(json.fetch('members')).to eq []
          end
        end

        context 'members in this administrative division have been changed' do
          let(:member_to_edit_1) { household1A.members.first }
          let(:member_to_edit_2) { household1A.members.second }
          let(:member_to_add) { build(:member, household: household1A) }
          let(:household_enrollment_record_to_add) { build(:household_enrollment_record, household: household1B, enrollment_period: enrollment_period) }
          let(:changed_members_ids_by_created_at) {
            [member_to_edit_1, member_to_edit_2, member_to_add, *household_enrollment_record_to_add.household.members].sort_by(&:created_at).map(&:id)
          }

          before do
            PaperTrail.without_versioning {
              member_to_edit_1.update_attributes(full_name: 'foo') # edit member in second_ad_a
              member_to_edit_2.update_attributes(phone_number: '123456') # edit member in second_ad_a
              member_to_add.save! # add member to second_ad_a
              household_enrollment_record_to_add.save! # add household enrollment record for household in second_ad_a. this should update all members for this household.
            }
            get provider_members_url(provider1, limit: 3, page_key: json.fetch('page_key')), headers: token_auth_header(provider_user1), as: :json
          end

          it 'returns the first page of changed members for the administrative division' do
            expect(response).to be_successful
            expect(json.fetch('has_more')).to be_truthy
            expect(json.fetch('page_key')).to be_truthy
            expect(json.fetch('members').map { |x| x['id'] }).to match_array(changed_members_ids_by_created_at.first(3))
            expect(json.fetch('members').first.keys).to match_array(readable_member_fields)
          end

          context 'next page request' do
            before do
              get provider_members_url(provider1, limit: 3, page_key: json.fetch('page_key')), headers: token_auth_header(provider_user1), as: :json
            end

            it 'returns the second (last) page of changed members for the administrative division' do
              expect(response).to be_successful
              expect(json.fetch('has_more')).to be_falsey
              expect(json.fetch('page_key')).to be_truthy
              expect(json.fetch('members').map { |x| x['id'] }).to match_array(changed_members_ids_by_created_at.last(3))
              expect(json.fetch('members').first.keys).to match_array(readable_member_fields)
            end

            context 'next batch request' do
              let(:request_page_key) { json.fetch('page_key') }

              before do
                get provider_members_url(provider1, limit: 3, page_key: request_page_key), headers: token_auth_header(provider_user1), as: :json
              end

              it 'returns an empty page with the same page key' do
                expect(response).to be_successful
                expect(json.fetch('has_more')).to be_falsey
                expect(json.fetch('page_key')).to eq request_page_key
                expect(json.fetch('members')).to eq []
              end
            end
          end
        end
      end
    end

    context 'if request is a provider from a different administrative division' do
      before do
        get provider_members_url(provider2, limit: page_size), headers: token_auth_header(provider_user2), as: :json
      end

      it 'returns a page of members for different administrative division' do
        expect(response).to be_successful
        expect(json.fetch('has_more')).to be_falsey
        expect(json.fetch('page_key')).to be_truthy
        expect(json.fetch('members').size).to eq 9
        expect(json.fetch('members').first.keys).to match_array(readable_member_fields)
      end
    end
  end

  describe "POST /members", use_database_rewinder: true do
    let!(:another_member) { create(:member, photo_id: nil) }

    context 'when the request is sent from a enrollment worker' do
      before do
        expect do
          post members_url, params: params, headers: token_auth_header(enrollment_user), as: :json
        end.to change(Member, :count).by(1)
      end

      context 'when the member has a medical_record_number' do
        let(:params) { build(:member, household: household1A).attributes.
          slice(*writable_member_fields).
          merge(medical_record_number: 123456).
          stringify_keys
        }

        it "creates a member and medical_record_numbers field is set correctly" do
          assert_successful_member_post
          reloaded_member = Member.find(params["id"])
          expect(reloaded_member.medical_record_numbers).to eq ({
            'primary' => 123456
          }).stringify_keys
        end
      end

      context 'when the member does not have a medical_record_number' do
        let(:params) { build(:member, household: household1A).attributes.
          slice(*writable_member_fields).
          merge(medical_record_number: nil).
          stringify_keys
        }

        it "creates a member with an empty medical_record_numbers hash" do
          assert_successful_member_post
          reloaded_member = Member.find(params["id"])
          expect(reloaded_member.medical_record_numbers).to eq ({})
        end
      end
    end

    context 'when the request is sent from a provider user' do
      before do
        expect do
          post members_url, params: params, headers: token_auth_header(provider_user1), as: :json
        end.to change(Member, :count).by(1)
      end

      context 'when member has a valid card_id' do
        let(:card) { create(:card) }
        let(:params) { build(:member, household: household1A, card: card).attributes.
          slice(*writable_member_fields).
          merge(medical_record_number: 123456).
          stringify_keys
        }

        it "creates a member" do
          assert_successful_member_post
          assert_medical_record_number_is_correct
          expect(json.fetch('card_id')).to_not be_nil
        end
      end

      context 'when member does not have a card_id' do
        let(:params) { build(:member, household: household1A).attributes.
          slice(*(writable_member_fields - ['card_id'])).
          merge(medical_record_number: 123456).
          stringify_keys
        }

        it "creates a member and sets card_id to nil" do
          assert_successful_member_post
          assert_medical_record_number_is_correct
          expect(json.fetch('card_id')).to be_nil
        end
      end

      context 'when member has a card_id taken by someone else' do
        let(:member) { build(:member, household: household1A, card_id: another_member.card_id) }
        let(:params) { member.attributes.
          slice(*writable_member_fields).
          merge(medical_record_number: 123456).
          stringify_keys
        }

        it "creates a member and sets card_id to nil" do
          assert_successful_member_post
          assert_medical_record_number_is_correct
          expect(json.fetch('card_id')).to be_nil
        end
      end
    end

    def assert_successful_member_post
      expect(response).to be_created
      returned_fields = writable_member_fields - %w[birthdate card_id enrolled_at]
      expect(json.slice(*returned_fields)).to eq params.slice(*returned_fields)
      expect(json.fetch('birthdate').to_date).to eq params.fetch('birthdate')
      expect(json.fetch('enrolled_at')).to match_timestamp params.fetch('enrolled_at')
      expect(json.keys).to_not include(*%w[photo_id])
    end

    def assert_medical_record_number_is_correct
      expect(response).to be_created
      reloaded_member = Member.find(params["id"])
      expect(reloaded_member.medical_record_numbers).to eq ({
        provider_user1.provider_id.to_s => params["medical_record_number"]
      }).stringify_keys
    end
  end

  describe "PATCH /members/:id" do
    let!(:member) { create(:member, full_name: 'abc', gender: 'M', card_id: nil, medical_record_numbers: ({
        'primary' => 123,
        "#{provider1.id}" => 456
      }).stringify_keys
    )}

    context 'when the request is sent from a provider user' do
      before do
        expect do
          patch member_url(member), params: params, headers: token_auth_header(provider_user1), as: :json
          member.reload
        end.to change { member.reload.updated_at }
      end

      context 'when the patch params include medical_record_number' do
        let(:params) {
          build(:member, gender: 'M').attributes.
            slice(*%w[full_name gender card_id phone_number]).
            merge(medical_record_number: 999)
        }

        it "member medical record number for that provider should be changed" do
          expect(member.reload.medical_record_numbers).to eq ({
            'primary' => 123,
            "#{provider1.id}" => 999
          }).stringify_keys
        end
      end
    end

    context 'when the request is sent from an enrollment worker' do
      before do
        expect do
          patch member_url(member), params: params, headers: token_auth_header(enrollment_user), as: :json
          member.reload
        end.to change { member.reload.updated_at }
      end

      context 'when the patch params includes medical_record_number' do
        let(:params) {
          build(:member, gender: 'M').attributes.
            slice(*%w[full_name gender card_id phone_number]).
            merge(medical_record_number: 999)
        }

        it 'member should be patched successfully' do
          assert_successful_member_patch
          expect(member.reload.card_id).to be member.card_id
        end

        it "member primary medical record number should be changed" do
          expect(member.reload.medical_record_numbers).to eq ({
            'primary' => 999,
            "#{provider1.id}" => 456
          }).stringify_keys
        end
      end

      context 'when the patch params has a card_id not in the system' do
        let(:params) { params = build(:member, card_id: 'RWI000000').attributes.slice(*%w[full_name gender card_id phone_number]) }

        it 'member should be patched successfully and card_id set to null' do
          assert_successful_member_patch
          expect(member.reload.card_id).to be nil
        end
      end

      context 'when the patch params has a card_id that has been taken by another member' do
        let(:another_member) { create(:member) }
        let(:params) { params = build(:member, card_id: another_member.card_id).attributes.slice(*%w[full_name gender card_id phone_number]) }

        it 'member should be patched successfully and card_id set to null' do
          assert_successful_member_patch
          expect(member.reload.card_id).to be nil
        end
      end

      def assert_successful_member_patch
        expect(response).to be_successful
        expect(json.keys).to include(*%w[id household_id created_at absentee card_id full_name gender age phone_number fingerprints_guid membership_number medical_record_number photo_url])
        expect(json.fetch('id')).to eq member.id

        applied = %w[full_name gender phone_number]
        expect(json.slice(*applied)).to eq params.slice(*applied)
      end
    end

    context 'when the request is sent as multipart/form-data' do
      let(:member) { create(:member,
        photo: File.open(Rails.root.join("spec/factories/members/photo1.jpg")),
        national_id_photo: File.open(Rails.root.join("spec/factories/members/national_id_photo1.jpg")))
      }

      let(:params) { member.
        attributes.
        slice(*%w[full_name gender card_id phone_number]).merge({
          photo: fixture_file_upload('spec/factories/members/photo2.jpg'),
          national_id_photo: fixture_file_upload('spec/factories/members/national_id_photo2.jpg')
        })
      }

      it 'updates the sent attributes as well as photo and national_id_photo on a member' do
        expect do
          patch member_url(member), params: params, headers: token_auth_header(provider_user1), as: :multipart_form
          member.reload
        end.
          to change { member.updated_at }.
          and change { member.photo_id }.
          and change { member.national_id_photo_id }

        expect(response).to be_successful
        expect(json.keys).to include(*%w[id household_id created_at absentee card_id full_name gender age phone_number fingerprints_guid photo_url national_id_photo_url membership_number medical_record_number])
        expect(json.fetch('id')).to eq member.id
        expect(json.fetch('photo_url')).to be
        expect(json.fetch('national_id_photo_url')).to be

        applied = %w[full_name gender card_id phone_number]
        expect(json.slice(*applied)).to eq params.slice(*applied)
      end
    end
  end
end
