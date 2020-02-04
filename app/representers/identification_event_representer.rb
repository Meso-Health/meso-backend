class IdentificationEventRepresenter < ApplicationRepresenter
  property :id, skip_parse: ->(**) { persisted? }
  property :occurred_at, skip_parse: ->(**) { persisted? }
  property :provider_id, writeable: false
  property :member_id, skip_parse: ->(**) { persisted? }
  property :user_id, writeable: false
  property :accepted, skip_parse: ->(**) { persisted? }
  property :search_method, skip_parse: ->(**) { persisted? }
  property :photo_verified, skip_parse: ->(**) { persisted? }
  property :through_member_id, render_nil: true, skip_parse: ->(**) { persisted? }
  property :clinic_number, render_nil: true, skip_parse: ->(**) { persisted? }
  property :clinic_number_type, render_nil: true, skip_parse: ->(**) { persisted? }
  property :dismissed
  property :fingerprints_verification_result_code
  property :fingerprints_verification_confidence
  property :fingerprints_verification_tier
end
