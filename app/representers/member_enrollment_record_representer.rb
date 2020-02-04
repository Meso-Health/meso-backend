# This will handle both POST and GET requests

class MemberEnrollmentRecordRepresenter < ApplicationRepresenter
  property :id, skip_parse: ->(**) { persisted? }
  property :enrolled_at, skip_parse: ->(**) { persisted? }
  property :user_id, skip_parse: ->(**) { persisted? }
  property :member_id, skip_parse: ->(**) { persisted? }
  property :note, render_nil: true
  property :membership_number, getter: ->(**) { member&.membership_number }, writeable: false
  property :enrollment_period_id, skip_parse: ->(**) { persisted? }
end
