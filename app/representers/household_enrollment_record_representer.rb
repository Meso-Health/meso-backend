# This representer is used for both GET and POST requests.

class HouseholdEnrollmentRecordRepresenter < ApplicationRepresenter
  property :id, skip_parse: ->(**) { persisted? }
  property :enrolled_at, skip_parse: ->(**) { persisted? }
  property :user_id, skip_parse: ->(**) { persisted? }
  property :enrollment_period_id, skip_parse: ->(**) { persisted? }
  property :household_id, skip_parse: ->(**) { persisted? }
  property :paying, skip_parse: ->(**) { persisted? }
  property :renewal, skip_parse: ->(**) { persisted? }
  property :administrative_division_id, skip_parse: ->(**) { persisted? }
end
