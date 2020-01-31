class MembershipPaymentRepresenter < ApplicationRepresenter
  property :id
  property :receipt_number, skip_parse: ->(**) { persisted? }
  property :payment_date, skip_parse: ->(**) { persisted? }
  property :annual_contribution_fee, skip_parse: ->(**) { persisted? }
  property :registration_fee, skip_parse: ->(**) { persisted? }
  property :qualifying_beneficiaries_fee, skip_parse: ->(**) { persisted? }
  property :penalty_fee, skip_parse: ->(**) { persisted? }
  property :other_fee, skip_parse: ->(**) { persisted? }
  property :card_replacement_fee, skip_parse: ->(**) { persisted? }
  property :household_enrollment_record_id, skip_parse: ->(**) { persisted? }
end
