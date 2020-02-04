class HouseholdEnrollmentRecordsController < ApplicationController
  def index
    user_administrative_division = @current_user.administrative_division

    if user_administrative_division.nil?
      error_message = "@current_user does not have an administrative division. #{@current_user}"
      Rollbar.error error_message
      render json: { errors: error_message }, status: 422
      return
    end

    current_enrollment_period = EnrollmentPeriod.where(administrative_division: user_administrative_division.self_and_ancestors).active_now.first
    administrative_division_ids = AdministrativeDivision.self_and_descendants_ids(@current_user.administrative_division)

    households = Household
      .where(households: { administrative_division_id: administrative_division_ids })
      .includes(household_enrollment_records: :enrollment_period)
      .includes(:membership_payments)
      .includes(members: :photo_attachment)
      .includes(:member_enrollment_records)
      .order(:created_at)

    member_count = Member.where(household: households).count
    member_last_updated_at = Member.where(household: households).maximum(:updated_at).to_i
    household_count = households.count
    household_last_updated_at = households.maximum(:updated_at)
    household_enrollment_record_count = HouseholdEnrollmentRecord.count
    household_enrollment_record_last_updated_at = HouseholdEnrollmentRecord.maximum(:updated_at).to_i
    member_enrollment_record_count = MemberEnrollmentRecord.count
    member_enrollment_record_last_updated_at = MemberEnrollmentRecord.maximum(:updated_at).to_i
    membership_payment_count = MembershipPayment.count
    membership_payment_last_updated_at = MembershipPayment.maximum(:updated_at).to_i
    cache_key = "households/query-" \
                "#{member_count}-#{member_last_updated_at}-" \
                "#{household_enrollment_record_count}-#{household_enrollment_record_last_updated_at}-" \
                "#{membership_payment_count}-#{membership_payment_last_updated_at}-" \
                "#{member_enrollment_record_count}-#{member_enrollment_record_last_updated_at}-" \
                "#{household_count}-#{household_last_updated_at}-" \
                "#{current_enrollment_period&.id}"
    if stale?(households, etag: cache_key)
      render json: HouseholdEnrollmentRepresenter.for_collection.new(households).to_json(current_enrollment_period_id: current_enrollment_period&.id)
    end
  end

  def create
    household_enrollment_record = HouseholdEnrollmentRecord.new

    representer = HouseholdEnrollmentRecordRepresenter.new(household_enrollment_record)
    representer.from_hash(params)

    household_enrollment_record.save_with_id_collision!

    render json: representer.to_json, status: :created
  end
end
