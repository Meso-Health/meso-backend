class ReferralRepresenter < ApplicationRepresenter
  property :id, skip_parse: ->(**) { persisted? }
  property :encounter_id, writeable: false
  # sending facility is the facility that requested/created the referral
  # we need to include this so that we can display the link from the inbound encounter
  # without needing to make a second request
  property :sending_facility,
           getter: ->(**) { encounter&.provider&.name },
           writeable: false
  # receiving_encounter_id is the encounter with the matching inbound_referral_date = referral.date
  property :receiving_encounter_id,  writeable: false, render_nil: true
  property :receiving_facility
  property :reason
  property :number
  property :date
end
