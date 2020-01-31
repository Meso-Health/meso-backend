# This representer is reading-only, not to be used in POST requests.

class HouseholdEnrollmentRepresenter < ApplicationRepresenter
  property :id, writeable: false
  property :enrolled_at, writeable: false
  property :administrative_division_id, writeable: false
  property :address, writeable: false, render_nil: true

  collection :members,
    decorator: MemberEnrollmentRepresenter,
    writeable: false

  collection :member_enrollment_records,
    decorator: MemberEnrollmentRecordRepresenter,
    writeable: false

  collection :active_membership_payments,
    decorator: MembershipPaymentRepresenter,
    writeable: false,
    getter: -> (options:, **) {
      membership_payments.select { |membership_payment| membership_payment.household_enrollment_record.enrollment_period_id == options[:current_enrollment_period_id] }
    }

  property :active_household_enrollment_record,
    decorator: HouseholdEnrollmentRecordRepresenter,
    writeable: false,
    getter: -> (options:, **) {
      household_enrollment_records.find { |household_enrollment_record| household_enrollment_record.enrollment_period_id == options[:current_enrollment_period_id] }
    },
    render_nil: true
end
