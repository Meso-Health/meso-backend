# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20191213125900) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "pg_stat_statements"
  enable_extension "pgcrypto"
  enable_extension "fuzzystrmatch"

  create_table "administrative_divisions", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "level", null: false
    t.string "code"
    t.integer "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "index_administrative_divisions_on_parent_id"
  end

  create_table "attachments", id: :string, limit: 32, force: :cascade do |t|
    t.string "file_uid", null: false
    t.string "file_name"
    t.integer "file_width"
    t.integer "file_height"
    t.integer "file_size"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["file_uid"], name: "index_attachments_on_file_uid", unique: true
  end

  create_table "attachments_encounters", id: :serial, force: :cascade do |t|
    t.string "attachment_id", limit: 32, null: false
    t.uuid "encounter_id", null: false
    t.index ["attachment_id", "encounter_id"], name: "index_attachments_encounters_on_attachment_id_and_encounter_id", unique: true
  end

  create_table "authentication_tokens", id: :string, limit: 8, force: :cascade do |t|
    t.string "secret_digest", limit: 64, null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "expires_at", null: false
    t.datetime "revoked_at"
    t.index ["user_id"], name: "index_authentication_tokens_on_user_id"
  end

  create_table "billables", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "type", default: "unspecified", null: false
    t.string "name", null: false
    t.string "composition"
    t.string "unit"
    t.string "accounting_group"
    t.boolean "active", default: true, null: false
    t.boolean "reviewed", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "requires_lab_result", default: false, null: false
  end

  create_table "card_batches", id: :serial, force: :cascade do |t|
    t.string "prefix"
    t.text "reason", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "cards", id: :string, limit: 9, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "card_batch_id", null: false
    t.datetime "revoked_at"
    t.string "revocation_reason"
    t.index ["card_batch_id"], name: "index_cards_on_card_batch_id"
  end

  create_table "diagnoses", id: :serial, force: :cascade do |t|
    t.string "description", null: false
    t.string "icd_10_codes", array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "search_aliases", default: [], null: false, array: true
    t.boolean "active", default: true, null: false
  end

  create_table "diagnoses_diagnoses_groups", id: false, force: :cascade do |t|
    t.integer "diagnoses_group_id", null: false
    t.integer "diagnosis_id", null: false
    t.index ["diagnoses_group_id"], name: "index_diagnoses_diagnoses_groups_on_diagnoses_group_id"
    t.index ["diagnosis_id"], name: "index_diagnoses_diagnoses_groups_on_diagnosis_id"
  end

  create_table "diagnoses_encounters", id: false, force: :cascade do |t|
    t.integer "diagnosis_id", null: false
    t.uuid "encounter_id", null: false
    t.index ["diagnosis_id"], name: "index_diagnoses_encounters_on_diagnosis_id"
    t.index ["encounter_id"], name: "index_diagnoses_encounters_on_encounter_id"
  end

  create_table "diagnoses_groups", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "encounter_items", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "encounter_id", null: false
    t.integer "quantity", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "price_schedule_id", null: false
    t.boolean "price_schedule_issued", default: false, null: false
    t.boolean "stockout", default: false, null: false
    t.integer "surgical_score"
    t.index ["encounter_id"], name: "index_encounter_items_on_encounter_id"
    t.index ["price_schedule_id"], name: "index_encounter_items_on_price_schedule_id"
  end

  create_table "encounters", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "provider_id", null: false
    t.integer "user_id", null: false
    t.uuid "member_id", null: false
    t.uuid "identification_event_id"
    t.datetime "occurred_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "backdated_occurred_at", default: false, null: false
    t.boolean "has_fever"
    t.string "visit_type"
    t.string "adjudication_state"
    t.integer "adjudicator_id"
    t.datetime "adjudicated_at"
    t.string "adjudication_comment"
    t.uuid "revised_encounter_id"
    t.text "provider_comment"
    t.text "claim_id", null: false
    t.datetime "submitted_at"
    t.datetime "prepared_at"
    t.uuid "reimbursement_id"
    t.string "patient_outcome"
    t.integer "custom_reimbursal_amount"
    t.date "inbound_referral_date"
    t.string "visit_reason"
    t.string "submission_state", null: false
    t.date "discharge_date"
    t.uuid "referral_id"
    t.datetime "audited_at"
    t.integer "auditor_id"
    t.string "adjudication_reason_category"
    t.integer "copayment_amount", default: 0, null: false
    t.string "copayment_comment"
    t.index ["adjudicator_id"], name: "index_encounters_on_adjudicator_id"
    t.index ["auditor_id"], name: "index_encounters_on_auditor_id"
    t.index ["claim_id"], name: "index_encounters_on_claim_id"
    t.index ["identification_event_id"], name: "index_encounters_on_identification_event_id"
    t.index ["member_id"], name: "index_encounters_on_member_id"
    t.index ["provider_id"], name: "index_encounters_on_provider_id"
    t.index ["referral_id"], name: "index_encounters_on_referral_id"
    t.index ["reimbursement_id"], name: "index_encounters_on_reimbursement_id"
    t.index ["revised_encounter_id"], name: "index_encounters_on_revised_encounter_id"
    t.index ["user_id"], name: "index_encounters_on_user_id"
  end

  create_table "enrollment_periods", id: :serial, force: :cascade do |t|
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "coverage_start_date", null: false
    t.date "coverage_end_date", null: false
    t.integer "administrative_division_id", null: false
    t.index ["administrative_division_id"], name: "index_enrollment_periods_on_administrative_division_id"
  end

  create_table "household_enrollment_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "enrolled_at", null: false
    t.uuid "household_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "enrollment_period_id", null: false
    t.jsonb "invalid_attributes", default: {}, null: false
    t.boolean "declined", default: false, null: false
    t.boolean "paying", default: false, null: false
    t.integer "administrative_division_id"
    t.boolean "renewal", default: false, null: false
    t.index ["administrative_division_id"], name: "index_household_enrollment_records_on_a_d_id"
    t.index ["enrollment_period_id"], name: "index_household_enrollment_records_on_enrollment_period_id"
    t.index ["household_id"], name: "index_household_enrollment_records_on_household_id"
    t.index ["user_id"], name: "index_household_enrollment_records_on_user_id"
  end

  create_table "households", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "photo_id", limit: 32
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "enrolled_at", null: false
    t.uuid "merged_from_household_id"
    t.integer "administrative_division_id", null: false
    t.string "address"
    t.index ["administrative_division_id"], name: "index_households_on_administrative_division_id"
  end

  create_table "identification_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "occurred_at", null: false
    t.integer "provider_id", null: false
    t.uuid "member_id", null: false
    t.integer "user_id", null: false
    t.boolean "accepted"
    t.string "search_method", null: false
    t.boolean "photo_verified"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "through_member_id"
    t.integer "clinic_number"
    t.string "clinic_number_type"
    t.boolean "dismissed", default: false
    t.string "dismissal_reason"
    t.integer "fingerprints_verification_result_code"
    t.float "fingerprints_verification_confidence"
    t.string "fingerprints_verification_tier"
    t.index ["member_id"], name: "index_identification_events_on_member_id"
    t.index ["provider_id"], name: "index_identification_events_on_provider_id"
    t.index ["through_member_id"], name: "index_identification_events_on_through_member_id"
    t.index ["user_id"], name: "index_identification_events_on_user_id"
  end

  create_table "lab_results", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "encounter_item_id", null: false
    t.string "result", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["encounter_item_id"], name: "index_lab_results_on_encounter_item_id"
  end

  create_table "member_enrollment_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "enrolled_at", null: false
    t.uuid "member_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "photo_id", limit: 32
    t.text "note"
    t.boolean "needs_review", default: false, null: false
    t.integer "enrollment_period_id", null: false
    t.jsonb "invalid_attributes", default: {}, null: false
    t.boolean "absentee"
    t.index ["enrollment_period_id"], name: "index_member_enrollment_records_on_enrollment_period_id"
    t.index ["member_id"], name: "index_member_enrollment_records_on_member_id"
    t.index ["user_id"], name: "index_member_enrollment_records_on_user_id"
  end

  create_table "members", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "full_name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "card_id", limit: 9
    t.date "birthdate", null: false
    t.string "birthdate_accuracy", limit: 1, null: false
    t.string "photo_id", limit: 32
    t.string "national_id_photo_id", limit: 32
    t.uuid "household_id"
    t.string "gender", limit: 1, null: false
    t.uuid "fingerprints_guid"
    t.string "phone_number"
    t.datetime "enrolled_at", null: false
    t.string "preferred_language"
    t.string "preferred_language_other"
    t.uuid "merged_from_member_id"
    t.string "membership_number"
    t.string "profession"
    t.string "relationship_to_head"
    t.datetime "archived_at"
    t.string "archived_reason"
    t.jsonb "medical_record_numbers", default: {}
    t.uuid "original_member_id"
    t.index ["card_id"], name: "index_members_on_card_id", unique: true
    t.index ["created_at"], name: "index_members_on_created_at"
    t.index ["household_id"], name: "index_members_on_household_id"
    t.index ["medical_record_numbers"], name: "index_members_on_medical_record_numbers", using: :gin
    t.index ["membership_number"], name: "index_members_on_membership_number"
    t.index ["original_member_id"], name: "index_members_on_original_member_id"
  end

  create_table "membership_payments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "receipt_number", null: false
    t.date "payment_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "annual_contribution_fee", default: 0, null: false
    t.integer "qualifying_beneficiaries_fee", default: 0, null: false
    t.integer "registration_fee", default: 0, null: false
    t.integer "penalty_fee", default: 0, null: false
    t.integer "other_fee", default: 0, null: false
    t.integer "card_replacement_fee", default: 0, null: false
    t.uuid "household_enrollment_record_id", null: false
    t.index ["household_enrollment_record_id"], name: "index_membership_payments_on_household_enrollment_record_id"
  end

  create_table "patient_experiences", force: :cascade do |t|
    t.integer "score", null: false
    t.uuid "encounter_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["encounter_id"], name: "index_patient_experiences_on_encounter_id"
  end

  create_table "payments", id: :serial, force: :cascade do |t|
    t.integer "provider_id", null: false
    t.integer "amount", null: false
    t.string "type", null: false
    t.date "effective_date", null: false
    t.datetime "paid_at", null: false
    t.jsonb "details", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider_id", "type", "effective_date"], name: "index_payments_on_provider_id_and_type_and_effective_date", unique: true
    t.index ["provider_id"], name: "index_payments_on_provider_id"
  end

  create_table "payments_transfers", id: false, force: :cascade do |t|
    t.integer "payment_id", null: false
    t.integer "transfer_id", null: false
    t.index ["payment_id", "transfer_id"], name: "index_payments_transfers_on_payment_id_and_transfer_id"
  end

  create_table "pilot_regions", id: :serial, force: :cascade do |t|
    t.integer "administrative_division_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["administrative_division_id"], name: "index_pilot_regions_on_administrative_division_id"
  end

  create_table "price_schedules", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "provider_id", null: false
    t.uuid "billable_id", null: false
    t.datetime "issued_at", null: false
    t.integer "price", null: false
    t.uuid "previous_price_schedule_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["billable_id"], name: "index_price_schedules_on_billable_id"
    t.index ["previous_price_schedule_id"], name: "index_price_schedules_on_previous_price_schedule_id"
    t.index ["provider_id"], name: "index_price_schedules_on_provider_id"
  end

  create_table "providers", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "security_pin", limit: 4, default: "0000", null: false
    t.integer "administrative_division_id", null: false
    t.string "provider_type", default: "unclassified", null: false
    t.integer "diagnoses_group_id"
    t.boolean "contracted", default: true, null: false
    t.index ["administrative_division_id"], name: "index_providers_on_administrative_division_id"
    t.index ["diagnoses_group_id"], name: "index_providers_on_diagnoses_group_id"
  end

  create_table "referrals", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "receiving_facility", null: false
    t.string "reason", null: false
    t.string "number"
    t.uuid "encounter_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "date", null: false
    t.index ["encounter_id"], name: "index_referrals_on_encounter_id"
  end

  create_table "reimbursements", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "provider_id", null: false
    t.integer "total", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "payment_date"
    t.jsonb "payment_field"
    t.index ["provider_id"], name: "index_reimbursements_on_provider_id"
    t.index ["user_id"], name: "index_reimbursements_on_user_id"
  end

  create_table "transfers", id: :serial, force: :cascade do |t|
    t.string "description"
    t.integer "amount", null: false
    t.string "stripe_account_id", null: false
    t.string "stripe_transfer_id", null: false
    t.string "stripe_payout_id"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "initiated_at", null: false
    t.index ["user_id"], name: "index_transfers_on_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "role", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.string "password_digest"
    t.integer "provider_id"
    t.string "email"
    t.datetime "deleted_at"
    t.integer "administrative_division_id"
    t.integer "adjudication_limit"
    t.index ["administrative_division_id"], name: "index_users_on_administrative_division_id"
    t.index ["provider_id"], name: "index_users_on_provider_id"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "versions", id: :serial, force: :cascade do |t|
    t.string "item_type", null: false
    t.string "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit", null: false
    t.jsonb "object"
    t.datetime "created_at", null: false
    t.jsonb "object_changes"
    t.string "release_commit_sha", null: false
    t.string "source"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "administrative_divisions", "administrative_divisions", column: "parent_id"
  add_foreign_key "attachments_encounters", "attachments"
  add_foreign_key "attachments_encounters", "encounters"
  add_foreign_key "authentication_tokens", "users"
  add_foreign_key "cards", "card_batches"
  add_foreign_key "encounter_items", "encounters"
  add_foreign_key "encounter_items", "price_schedules"
  add_foreign_key "encounters", "encounters", column: "revised_encounter_id"
  add_foreign_key "encounters", "identification_events"
  add_foreign_key "encounters", "members"
  add_foreign_key "encounters", "providers"
  add_foreign_key "encounters", "referrals"
  add_foreign_key "encounters", "reimbursements"
  add_foreign_key "encounters", "users"
  add_foreign_key "encounters", "users", column: "adjudicator_id"
  add_foreign_key "encounters", "users", column: "auditor_id"
  add_foreign_key "household_enrollment_records", "administrative_divisions"
  add_foreign_key "household_enrollment_records", "enrollment_periods"
  add_foreign_key "household_enrollment_records", "households"
  add_foreign_key "household_enrollment_records", "users"
  add_foreign_key "households", "administrative_divisions"
  add_foreign_key "households", "attachments", column: "photo_id"
  add_foreign_key "identification_events", "members"
  add_foreign_key "identification_events", "members", column: "through_member_id"
  add_foreign_key "identification_events", "providers"
  add_foreign_key "identification_events", "users"
  add_foreign_key "lab_results", "encounter_items"
  add_foreign_key "member_enrollment_records", "attachments", column: "photo_id"
  add_foreign_key "member_enrollment_records", "enrollment_periods"
  add_foreign_key "member_enrollment_records", "members"
  add_foreign_key "member_enrollment_records", "users"
  add_foreign_key "members", "attachments", column: "national_id_photo_id"
  add_foreign_key "members", "attachments", column: "photo_id"
  add_foreign_key "members", "cards"
  add_foreign_key "members", "households"
  add_foreign_key "members", "members", column: "original_member_id"
  add_foreign_key "membership_payments", "household_enrollment_records"
  add_foreign_key "patient_experiences", "encounters"
  add_foreign_key "payments", "providers"
  add_foreign_key "price_schedules", "billables"
  add_foreign_key "price_schedules", "price_schedules", column: "previous_price_schedule_id"
  add_foreign_key "price_schedules", "providers"
  add_foreign_key "providers", "administrative_divisions"
  add_foreign_key "providers", "diagnoses_groups"
  add_foreign_key "referrals", "encounters"
  add_foreign_key "reimbursements", "providers"
  add_foreign_key "reimbursements", "users"
  add_foreign_key "transfers", "users"
  add_foreign_key "users", "administrative_divisions"
  add_foreign_key "users", "providers"
end
