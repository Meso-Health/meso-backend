require 'rails_helper'

RSpec.describe 'Encounters', type: :request do
  let(:readable_encounter_fields) do
    %w[id created_at occurred_at prepared_at backdated_occurred_at provider_id member_id user_id
       identification_event_id copayment_amount price encounter_items billables price_schedules diagnosis_ids
       has_fever clinic_number clinic_number_type visit_type visit_reason adjudication_state resubmitted provider_comment
       claim_id submitted_at referrals patient_outcome reimbursement_id reimbursal_amount reimbursement_completed_at reimbursement_created_at inbound_referral_date
       adjudicator_name submitter_name submission_state discharge_date diagnoses member_unconfirmed member_inactive_at_time_of_service
       inbound_referral_unlinked adjudicator_id adjudicated_at adjudication_reason adjudication_reason_category adjudication_comment
       revised_encounter_id auditor_name updated_at
      ]
  end
  let(:readable_encounter_with_member_fields) do
    readable_encounter_fields + ['member']
  end
  let(:readable_encounter_item_fields) do
    %w[id quantity encounter_id price_schedule_id price_schedule_issued stockout]
  end
  let(:readable_billable_fields) do
    %w[id active name composition type unit reviewed requires_lab_result accounting_group]
  end
  let(:readable_price_schedule_fields) do
    %w[id price issued_at billable_id provider_id previous_price_schedule_id]
  end
  let(:readable_referral_fields) do
    %w[id encounter_id receiving_facility reason number date receiving_encounter_id sending_facility]
  end
  let(:nonupdateable_encounter_fields) do
    %w[id identification_event_id member_id provider_id]
  end
  let(:updateable_encounter_fields) do
    %w[occurred_at prepared_at user_id submission_state inbound_referral_date discharge_date visit_type visit_reason provider_comment]
  end
  let(:writable_encounter_item_fields) do
    %w[id encounter_id quantity price_schedule_id price_schedule_issued stockout]
  end
  let(:writable_referral_fields) do
    %w[id encounter_id receiving_facility date number reason]
  end

  describe 'GET /encounters' do
    it 'returns a list of all encounters ordered by occurred_at' do
      provider = create(:provider)
      create(:encounter, :with_items, :with_diagnoses, :with_referrals, provider: provider, occurred_at: Time.zone.now,
             identification_event: build(:identification_event, clinic_number: 200, clinic_number_type: 'opd'))
      create(:encounter, :with_items, :with_diagnoses, :with_referrals, provider: create(:provider), occurred_at: Time.zone.now,
             identification_event: build(:identification_event, clinic_number: 8, clinic_number_type: 'delivery'))
      get encounters_url, headers: token_auth_header, as: :json
      expect(response).to be_successful
      expect(json.size).to eq 2
      expect(json.first.keys).to match_array(readable_encounter_with_member_fields)

      items = json.first.fetch('encounter_items')
      expect(items.size).to eq 2

      billables = json.first.fetch('billables')
      expect(billables.size).to eq 2
      expect(billables.first.keys).to match_array(readable_billable_fields)

      price_schedules = json.first.fetch('price_schedules')
      expect(price_schedules.size).to eq 2
      expect(price_schedules.first.keys).to match_array(readable_price_schedule_fields)

      referrals = json.first.fetch('referrals')
      expect(referrals.size).to eq 2
      expect(referrals.first.keys).to match_array(readable_referral_fields)

      diganosis_ids = json.first.fetch('diagnosis_ids')
      expect(diganosis_ids.size).to eq 2
      expect(diganosis_ids.first).to be_an Integer

      expect(json.first.fetch('clinic_number')).to eq 8
      expect(json.second.fetch('clinic_number')).to eq 200
      expect(json.first.fetch('clinic_number_type')).to eq 'delivery'
      expect(json.second.fetch('clinic_number_type')).to eq 'opd'
    end

    describe 'medical record number' do
      let(:provider1) { create(:provider) }
      let(:provider2) { create(:provider) }
      let(:user) { create(:user, :provider_admin, provider: provider1) }
      let(:member) { create(:member, medical_record_numbers: { provider1.id.to_s => 123, provider2.id.to_s => 456 }) }
      let!(:encounter1) { create(:encounter, provider: provider1, occurred_at: Time.zone.now, member: member) }
      let!(:encounter2) { create(:encounter, provider: provider2, occurred_at: 5.hours.ago, member: member) }

      before { get encounters_url, headers: token_auth_header(user), as: :json }

      it 'sets the medical record number based on the current user\'s provider' do
        expect(response).to be_successful
        expect(json.size).to eq 2
        expect(json.first['id']).to eq encounter1.id
        expect(json.first['member']['medical_record_number']).to eq 123

        expect(json.second['id']).to eq encounter2.id
        expect(json.second['member']['medical_record_number']).to eq 123
      end
    end
  end

  describe 'GET /providers/:id/encounters/returned' do
    let!(:provider1) { create(:provider) }
    let!(:provider2) { create(:provider) }
    let!(:encounter1) { create(:encounter, :returned, provider: provider1, occurred_at: 5.days.ago) }
    let!(:encounter2) { create(:encounter, :returned, provider: provider2, occurred_at: Time.zone.now) }
    let!(:encounter3) { create(:encounter, :approved, provider: provider1, occurred_at: Time.zone.now) }
    let!(:encounter4) { create(:encounter, provider: provider1, occurred_at: Time.zone.now) }
    let!(:encounter5) { create(:encounter, :returned, provider: provider1, occurred_at: Time.zone.now) }
    let!(:encounter6) { create(:encounter, :returned, provider: provider2, occurred_at: Time.zone.now) }
    let!(:user) { create(:user, :provider_admin) }
    let!(:adjudicator) { create(:user, :adjudication) }

    it 'returns a list of all returned encounters that need to be returned ordered by occurred_at' do
      get returned_provider_encounters_url(provider1), headers: token_auth_header, as: :json

      expect(response).to be_successful
      expect(json.size).to eq 2

      expect(json.first.keys).to match_array(readable_encounter_with_member_fields)
      expect(json.first.fetch('id')).to eq encounter5.id
      expect(json.second.fetch('id')).to eq encounter1.id

      expect(json.first.fetch('member').fetch('id')).to eq encounter5.member.id
      expect(json.second.fetch('member').fetch('id')).to eq encounter1.member.id
    end

    it 'returns the correct status code based on staleness of encounters' do
      get returned_provider_encounters_url(provider1), headers: token_auth_header, as: :json
      expect(response).to be_successful

      # No new returned encounters under that provider
      get returned_provider_encounters_url(provider1), headers: token_auth_header(user, additional_headers: { "HTTP_IF_NONE_MATCH": response.headers['ETag'] }), as: :json
      expect(response).to have_http_status(304)

      # New returned claim
      newly_created_returned_encounter = create(:encounter, :returned, provider: provider1, occurred_at: Time.zone.now)
      get returned_provider_encounters_url(provider1), headers: token_auth_header(user, additional_headers: { "HTTP_IF_NONE_MATCH": response.headers['ETag'] }), as: :json
      expect(response).to have_http_status(200)

      # No new returned encounters
      get returned_provider_encounters_url(provider1), headers: token_auth_header(user, additional_headers: { "HTTP_IF_NONE_MATCH": response.headers['ETag'] }), as: :json
      expect(response).to have_http_status(304)

      # One more returned claim.
      PaperTrail.without_versioning { encounter1.update_attribute(:adjudication_state, 'approved') }
      get returned_provider_encounters_url(provider1), headers: token_auth_header(user, additional_headers: { "HTTP_IF_NONE_MATCH": response.headers['ETag'] }), as: :json
      expect(response).to have_http_status(200)

      expect(json.size).to eq(2)
      expect(json.first.fetch('id')).to eq newly_created_returned_encounter.id
      expect(json.second.fetch('id')).to eq encounter5.id
    end
  end

  describe 'POST /providers/:id/encounters', use_database_rewinder: true do
    let!(:first_ad) { create(:administrative_division, level: 'first', code: '01') }
    let!(:second_ad) { create(:administrative_division, code: '04', level: 'second', parent: first_ad) }
    let!(:provider) { create(:provider) }
    let!(:user) { create(:user, :submission) }
    let(:household) { create(:household, administrative_division: second_ad) }
    let!(:member) { create(:member, photo: nil, household: household) } # ! generates member immediately to prevent the member and household photos from interfering with the Attachment count test

    let!(:identification_event) { create(:identification_event, provider: provider, member: member, user: user) }
    let!(:encounter) do
      build(
        :encounter,
        member: member,
        identification_event: identification_event,
        user: user,
        prepared_at: 2.days.ago,
        submitted_at: 1.day.ago
      )
    end

    let!(:diagnoses) { create_list(:diagnosis, 2) }
    let!(:price_schedule_1) { create(:price_schedule, provider: provider) }
    let!(:price_schedule_2) { create(:price_schedule, :with_previous, provider: provider) }
    let!(:price_schedule_2_prev) { price_schedule_2.previous_price_schedule }
    let!(:billable_1) { price_schedule_1.billable }
    let!(:billable_2) { price_schedule_2.billable }
    let!(:encounter_item_1) { build(:encounter_item, price_schedule: price_schedule_1, encounter: encounter) }
    let!(:encounter_item_2) { build(:encounter_item, price_schedule: price_schedule_2, price_schedule_issued: true, encounter: encounter) }
    let!(:referral) { build(:referral, encounter: encounter) }

    let(:params) do
      encounter.attributes.merge(
        encounter_items: [
          encounter_item_1.attributes,
          encounter_item_2.attributes
        ],
        referrals: [
          referral.attributes
        ],
        diagnosis_ids: diagnoses.map(&:id)
      ).except(
        'submission_state',
        'adjudication_state'
      )
    end
    let!(:lab_result_count) { 0 }
    let!(:attachment_count) { 0 }

    shared_examples :successful_response do |format|
      it 'successfully creates the encounter and related models, and returns them in a json response' do
        expect do
          post provider_encounters_url(provider), params: params, headers: token_auth_header(user), as: format
        end.
          to change(Encounter, :count).by(1).
            and change(EncounterItem, :count).by(2).
              and change(Referral, :count).by(1).
                and change(LabResult, :count).by(lab_result_count).
                  and change(Attachment, :count).by(attachment_count)

        expect(response).to be_created

        expect(json.fetch('id')).to eq encounter.id
        expect(json.fetch('provider_id')).to eq provider.id
        expect(json.fetch('member_id')).to eq member.id
        expect(json.fetch('user_id')).to eq user.id
        expect(json.fetch('identification_event_id')).to eq identification_event.id
        expect(json.fetch('backdated_occurred_at')).to eq encounter.backdated_occurred_at
        expect(json.fetch('copayment_amount')).to eq encounter.copayment_amount
        expect(json.fetch('has_fever')).to be encounter.has_fever
        expect(json.fetch('visit_type')).to eq encounter.visit_type
        expect(json.fetch('visit_reason')).to eq encounter.visit_reason
        # for some reason, the provider comment is blank when the format as multipart_form
        expect(json.fetch('provider_comment')).to eq encounter.provider_comment unless format == :multipart_form
        expect(json.fetch('claim_id')).to eq encounter.claim_id
        expect(json.fetch('adjudication_state')).to eq 'pending'

        items = json.fetch('encounter_items')
        expect(items.size).to eq 2
        expect(items.map { |x| x.fetch('encounter_id') }.uniq).to eq [encounter.id]
        expect(items.map { |x| x.fetch('price_schedule_id') }).to match_array [price_schedule_1.id, price_schedule_2.id]
        expect(items.map { |x| x.fetch('price_schedule_issued') }).to match_array [true, false]

        billables = json.fetch('billables')
        expect(billables.size).to eq 2
        expect(billables.map { |x| x.fetch('id') }).to match_array [billable_1.id, billable_2.id]

        price_schedules = json.fetch('price_schedules')
        expect(price_schedules.size).to eq 3
        expect(price_schedules.map { |x| x.fetch('id') }).to match_array [price_schedule_1.id, price_schedule_2.id, price_schedule_2_prev.id]

        expect(json.fetch('diagnosis_ids')).to match_array(diagnoses.map(&:id))

        if lab_result_count > 0
          lab_result = items.first.fetch('lab_result')
          expect(lab_result.keys).to match_array(%w[id result])
        end

        expect(json.fetch('form_urls').size).to eq 2 if attachment_count > 0

        expect(json.fetch('referrals').size).to eq 1
      end
    end

    context 'when the request is sent as JSON' do
      it_behaves_like :successful_response, :json

      # TODO: remove after android clients have updated to setting submission_state themselves
      context 'when the encounter is submitted without a submission_state' do
        context 'when the submission_state can be deduced from the timestamps' do
          let(:params) do
            encounter.attributes.merge(
              encounter_items: [
                encounter_item_1.attributes,
                encounter_item_2.attributes
              ],
              referrals: [
                referral.attributes
              ],
              diagnosis_ids: diagnoses.map(&:id)
            ).except(
              'submission_state'
            )
          end

          it_behaves_like :successful_response, :json
        end

        context 'when the submission_state cannot be deduced from the timestamps' do
          let(:params) do
            encounter.attributes.merge(
              encounter_items: [
                encounter_item_1.attributes,
                encounter_item_2.attributes
              ],
              referrals: [
                referral.attributes
              ],
              diagnosis_ids: diagnoses.map(&:id),
              prepared_at: nil,
              submitted_at: 1.day.ago
            ).except(
              'submission_state'
            )
          end

          it 'returns a method not allowed response' do
            post provider_encounters_url(provider), params: params, headers: token_auth_header(user), as: :json

            expect(response).to have_http_status(:method_not_allowed)
          end
        end
      end

      context 'when the encounter in the request has no claim_id' do
        let(:params) do
          encounter.attributes.merge(
            encounter_items: [
              encounter_item_1.attributes,
              encounter_item_2.attributes
            ],
            referrals: [
              referral.attributes
            ],
            diagnosis_ids: diagnoses.map(&:id)
          ).except(
            'claim_id'
          )
        end

        it_behaves_like :successful_response, :json
      end

      context 'when an encounter item includes a lab result' do
        let(:params) do
          encounter.attributes.merge(
            encounter_items: [
              encounter_item_1.attributes.merge(lab_result: attributes_for(:lab_result, encounter_item: encounter_item_1)),
              encounter_item_2.attributes
            ],
            referrals: [
              referral.attributes
            ],
            diagnosis_ids: diagnoses.map(&:id)
          )
        end
        let(:lab_result_count) { 1 }

        it_behaves_like :successful_response, :json
      end

      context 'when an encounter already exists but there is a duplicate POST of the same encounter' do
        let(:params) do
          encounter.attributes.merge(
            encounter_items: [
              encounter_item_1.attributes.merge(lab_result: attributes_for(:lab_result, encounter_item: encounter_item_1)),
              encounter_item_2.attributes
            ],
            referrals: [
              referral.attributes
            ],
            diagnosis_ids: diagnoses.map(&:id)
          )
        end

        before do
          post provider_encounters_url(provider), params: params, headers: token_auth_header(user), as: :json
        end

        it 'second post request is successful' do
          expect do
            post provider_encounters_url(provider), params: params, headers: token_auth_header(user), as: :json
          end.
            to change(Encounter, :count).by(0).
              and change(EncounterItem, :count).by(0).
                and change(Referral, :count).by(0)
          expect(response).to be_created
        end
      end
    end

    context 'when the request is sent as multipart/form-data' do
      let(:params) do
        encounter.attributes.merge(
          encounter_items: [
            encounter_item_1.attributes,
            encounter_item_2.attributes
          ],
          referrals: [
            referral.attributes
          ],
          diagnosis_ids: diagnoses.map(&:id),
          forms: [
            fixture_file_upload('spec/factories/encounters/form1.jpg'),
            fixture_file_upload('spec/factories/encounters/form2.jpg')
          ]
        ).except(
          :submission_state,
          :adjudication_state
        )
      end
      let(:attachment_count) { 2 }

      it_behaves_like :successful_response, :multipart_form
    end
  end

  describe 'PATCH /encounters/:id' do
    let!(:first_ad) { create(:administrative_division, level: 'first', code: '01') }
    let!(:second_ad) { create(:administrative_division, code: '04', level: 'second', parent: first_ad) }
    let(:user) { create(:user, :provider_admin) }

    let!(:member) { create(:member, membership_number: "123456", photo: nil) }
    let!(:encounter) { create(:encounter, user: user, member: member, provider: user.provider) }

    describe 'adjudicator updates adjudication_state' do
      let(:adjudicator) { create(:user, :adjudication) }
      let(:params) do
        {
          adjudication_state: adjudication_state,
          adjudication_comment: adjudication_comment,
          adjudicator_id: adjudicator.id,
          adjudicated_at: Time.zone.now
        }
      end

      before do
        patch encounter_url(encounter), params: params, headers: token_auth_header(adjudicator), as: :json
      end

      shared_examples 'successful adjudication response' do
        it 'updates the encounter and returns it in a json response' do
          expect(response).to be_successful
          expect(encounter.reload.adjudication_state).to eq adjudication_state
          expect(encounter.reload.adjudication_comment).to eq adjudication_comment
        end
      end

      context 'when an adjudicator approves a pending claim' do
        let(:adjudication_state) { 'approved' }
        let(:adjudication_comment) { nil }

        it_behaves_like 'successful adjudication response'
      end

      context 'when an adjudicator returns a pending claim' do
        let(:adjudication_state) { 'returned' }
        let(:adjudication_comment) { Faker::Lorem.sentence }

        it_behaves_like 'successful adjudication response'
      end

      context 'when an adjudicator rejects a pending claim' do
        let(:adjudication_state) { 'rejected' }
        let(:adjudication_comment) { Faker::Lorem.sentence }

        it_behaves_like 'successful adjudication response'
      end

      context 'when an approved claim already has a reimbursement' do
        let!(:reimbursement) { create(:reimbursement) }
        let!(:encounter) { reimbursement.encounters.first }
        let(:adjudication_state) { 'rejected' }
        let(:adjudication_comment) { Faker::Lorem.sentence }

        it 'returns 405 when the adjudicator tries to change the adjudication_state' do
          expect(response).to have_http_status(405)
          expect(encounter.reload.approved?).to be true
        end
      end

      context 'when the adjudication limit is nil' do
        let(:adjudication_state) { 'approved' }
        let(:adjudication_comment) { nil }

        it_behaves_like 'successful adjudication response'
      end

      context 'when adjudication limit is less than reimbursal amount' do
        let(:second_ad) { create(:administrative_division, :second) }
        let(:adjudicator) { create(:user, :adjudication, adjudication_limit: 100, administrative_division: second_ad) }
        let(:user) { create(:user, :provider_admin) }
        let(:adjudication_state) { 'approved' }
        let(:adjudication_comment) { nil }
        let!(:encounter) { create(:encounter, user: user, provider: user.provider, custom_reimbursal_amount: 100000)}

        it 'throws a 405 and the encounter is not adjudicated' do
          expect(response).to have_http_status(405)
          expect(encounter.reload.approved?).to be false
        end

      end
    end

    describe 'provider admin reviews claim' do
      let(:provider_admin) { create(:user, :provider_admin) }
      let(:encounter) { create(:encounter, :prepared, member: member) }
      let(:params) do
        {
          submission_state: submission_state,
          submitted_at: submitted_at,
          user_id: provider_admin.id
        }
      end

      before do
        patch encounter_url(encounter), params: params, headers: token_auth_header(provider_admin), as: :json
      end

      shared_examples 'successful response' do
        it 'updates the encounter and returns it in a json response' do
          expect(response).to be_successful
          expect(encounter.reload.user).to eq provider_admin
          expect(encounter.reload.submission_state).to eq submission_state
          expect(encounter.reload.submitted_at.to_i).to eq submitted_at.to_i
        end
      end

      context 'when a provider admin approves a prepared claim' do
        let(:submission_state) { 'submitted' }
        let(:submitted_at) { Time.zone.now }

        it_behaves_like 'successful response'
      end

      context 'when a provider admin marks a prepared claim as needs_revision' do
        let(:submission_state) { 'needs_revision' }
        let(:submitted_at) { nil }

        it_behaves_like 'successful response'
      end
    end

    describe 'claims preparer edits claim' do
      shared_examples 'successful edit response' do
        before do
          patch encounter_url(original_encounter), params: params, headers: token_auth_header(claims_preparer), as: :json
        end

        it 'successful response' do
          expect(response).to be_successful
          expect(json.keys).to match_array(readable_encounter_fields)
        end

        it 'updates expected fields on the encounter' do
          expect(json.slice(*nonupdateable_encounter_fields)).to eq original_encounter.slice(*nonupdateable_encounter_fields)

          updateable_encounter_date_fields = %w[occurred_at prepared_at inbound_referral_date discharge_date]
          expect(json.slice(*(updateable_encounter_fields - updateable_encounter_date_fields))).to eq params.slice(*(updateable_encounter_fields - updateable_encounter_date_fields))
          expect(json.fetch('occurred_at')).to match_timestamp params.fetch('occurred_at')
          expect(json.fetch('prepared_at')).to match_timestamp params.fetch('prepared_at')
          expect(json.fetch('inbound_referral_date').to_date).to eq params.fetch('inbound_referral_date').to_date
          expect(json.fetch('discharge_date').to_date).to eq params.fetch('discharge_date').to_date
          expect(json.fetch('reimbursal_amount')).to eq original_encounter.reload.reimbursal_amount
          expect(original_encounter.reload.custom_reimbursal_amount).to eq params[:custom_reimbursal_amount]
          expect(json.fetch('diagnosis_ids')).to match_array(params[:diagnosis_ids])
        end

        it 'updates encounter_items, deleting ones that have been removed, creating ones that have been added, and updating ones that have been edited' do
          response_encounter_items = json.fetch('encounter_items')
          writable_encounter_item_fields.each do |field|
            expect(response_encounter_items.map { |x| x.fetch(field) }).to match_array(params[:encounter_items].map { |x| x[field] })
          end
        end

        it 'updates referrals, deleting ones that have been removed, creating ones that have been added, and updating ones that have been edited' do
          response_referrals = json.fetch('referrals')
          (writable_referral_fields - ['date']).each do |field|
            expect(response_referrals.map { |x| x.fetch(field) }).to match_array(params[:referrals].map { |x| x[field] })
          end
          expect(response_referrals.map { |x| x.fetch('date').to_date }).to match_array(params[:referrals].map { |x| x['date'].to_date })
        end

        it 'updates the returned billables and price_schedules (corresponding to the updated encounter_items)' do
          response_billables = json.fetch('billables')
          expect(response_billables.map { |x| x.fetch('id') }).to match_array [billable_1.id, billable_2.id]

          response_price_schedules = json.fetch('price_schedules')
          expect(response_price_schedules.map { |x| x.fetch('id') }).to match_array [price_schedule_1.id, price_schedule_2.id, price_schedule_2_prev.id]
        end
      end

      describe 'claims preparer prepares a started (partial) claim' do
        let(:provider) { create(:provider, provider_type: 'general_hospital') }
        let!(:member) { create(:member, membership_number: "123456", photo: nil) } # ! generates member immediately to prevent the member and household photos from interfering with the Attachment count test
        let(:identification_user) { create(:user, :identification, provider: provider) }
        let(:claims_preparer) { create(:user, :submission, provider: provider) }

        let(:diagnoses) { create_list(:diagnosis, 2) }
        let(:price_schedule_1) { create(:price_schedule, provider: provider) }
        let(:price_schedule_2) { create(:price_schedule, :with_previous, provider: provider) }
        let(:price_schedule_2_prev) { price_schedule_2.previous_price_schedule }
        let(:billable_1) { price_schedule_1.billable }
        let(:billable_2) { price_schedule_2.billable }

        let!(:original_encounter) { create(:encounter, :started, provider: provider, member: member, user: identification_user) }
        let(:edited_encounter) { build(:encounter, :prepared, :with_inbound_referral_date, :with_discharge_date, :with_specified_diagnoses, id: original_encounter.id, diagnoses: diagnoses, patient_outcome: 'referred', user: claims_preparer) }
        let(:encounter_item_1) { build(:encounter_item, price_schedule: price_schedule_1, encounter: edited_encounter) }
        let(:encounter_item_2) { build(:encounter_item, price_schedule: price_schedule_2, price_schedule_issued: true, encounter: edited_encounter) }
        let(:referral) { build(:referral, encounter: edited_encounter) }

        let(:params) do
          edited_encounter.attributes.merge(
            encounter_items: [
              encounter_item_1.attributes,
              encounter_item_2.attributes
            ],
            referrals: [
              referral.attributes
            ],
            diagnosis_ids: diagnoses.map(&:id)
          )
        end

        it 'creates and deletes the expected number of records' do
          expect do
            patch encounter_url(original_encounter), params: params, headers: token_auth_header(claims_preparer), as: :json
          end.
            to change(Encounter, :count).by(0).
              and change(EncounterItem, :count).by(2).
                and change(Referral, :count).by(1)
        end

        it_behaves_like 'successful edit response'
      end

      describe 'claims preparer edits (re-prepares) a claim needing revision' do
        let(:provider) { create(:provider, provider_type: 'general_hospital') }
        let!(:member) { create(:member, membership_number: "123456", photo: nil) } # ! generates member immediately to prevent the member and household photos from interfering with the Attachment count test
        let(:identification_user) { create(:user, :identification, provider: provider) }
        let(:provider_admin_user) { create(:user, :provider_admin, provider: provider) }
        let(:claims_preparer) { create(:user, :submission, provider: provider) }

        let(:diagnoses) { create_list(:diagnosis, 3) }
        let(:price_schedule_1) { create(:price_schedule, provider: provider) }
        let(:price_schedule_2) { create(:price_schedule, :with_previous, provider: provider) }
        let(:price_schedule_2_prev) { price_schedule_2.previous_price_schedule }
        let(:billable_1) { price_schedule_1.billable }
        let(:billable_2) { price_schedule_2.billable }

        let!(:original_encounter) { create(:encounter, :needs_revision, :with_specified_diagnoses, diagnoses: diagnoses.first(2), provider: provider, member: member, user: provider_admin_user) }
        let!(:encounter_item_1) { create(:encounter_item, price_schedule: price_schedule_1, encounter: original_encounter, stockout: false, quantity: 10) }
        let!(:encounter_item_2) { create(:encounter_item, price_schedule: price_schedule_2_prev, encounter: original_encounter) }
        let!(:referral_1) { create(:referral, encounter: original_encounter) }
        let!(:referral_2) { create(:referral, encounter: original_encounter) }

        let(:edited_encounter) { build(:encounter, :prepared, :with_inbound_referral_date, :with_discharge_date, :with_specified_diagnoses, id: original_encounter.id, diagnoses: diagnoses.last(2), user: claims_preparer) }
        let!(:encounter_item_1_updated) { encounter_item_1.tap { |x| x.assign_attributes(stockout: true, quantity: 20, encounter: edited_encounter) } }
        let!(:encounter_item_3) { build(:encounter_item, price_schedule: price_schedule_2, price_schedule_issued: true, encounter: edited_encounter) }
        let!(:referral_1_updated) { build(:referral, id: referral_1.id, encounter: edited_encounter) }

        let(:params) do
          edited_encounter.attributes.merge(
            encounter_items: [
              encounter_item_1_updated.attributes,
              encounter_item_3.attributes
            ],
            referrals: [referral_1_updated.attributes],
            diagnosis_ids: edited_encounter.diagnosis_ids,
            custom_reimbursal_amount: 20000,
          )
        end

        it 'creates and deletes the expected number of records' do
          expect do
            patch encounter_url(original_encounter), params: params, headers: token_auth_header(claims_preparer), as: :json
          end.
            to change(Encounter, :count).by(0).
              and change(EncounterItem, :count).by(0). # 1 added, 1 deleted
               and change(Referral, :count).by(-1)
        end

        it_behaves_like 'successful edit response'
      end
    end

    describe 'provider user editing encounter forms' do
      let(:attachment) { create(:attachment, file: File.open(Rails.root.join('spec/factories/encounters/form1.jpg'))) }
      let!(:encounter) { create(:encounter, form_attachments: [attachment], user: user, provider: user.provider, member: member) }

      context 'when a request is made with new form attachments' do
        it 'updates the encounter with the new attachments' do
          params = { forms: [fixture_file_upload('spec/factories/encounters/form2.jpg')] }

          expect do
            patch encounter_url(encounter), params: params, headers: token_auth_header(user), as: :multipart_form
          end.
            to change { encounter.reload.forms.size }.from(1).to(2).
              and change(Attachment, :count).by(1)

          expect(response).to be_successful

          expect(json.keys).to match_array(readable_encounter_fields + ['form_urls'])
          expect(json.fetch('id')).to eq encounter.id
          expect(json.fetch('form_urls').size).to eq 2
        end
      end
    end
  end
end
