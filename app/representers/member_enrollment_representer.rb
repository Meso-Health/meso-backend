# This is only used within GET /household_enrollment_records
class MemberEnrollmentRepresenter < ApplicationRepresenter
  property :id
  property :card_id, render_nil: true
  property :full_name
  property :gender
  property :birthdate
  property :birthdate_accuracy
  property :phone_number, render_nil: true
  property :profession, render_nil: true
  property :membership_number, render_nil: true
  property :medical_record_number,
    getter: ->(options:, **) { 
      medical_record_number_from_key('primary')
    },
    writeable: false,
    render_nil: true

  property :relationship_to_head, render_nil: true
  property :household_id, skip_parse: ->(**) { persisted? }
  property :photo_url, exec_context: :decorator, writeable: false, render_nil: true
  property :enrolled_at, writeable: false
  property :archived_at, render_nil: true
  property :archived_reason, render_nil: true

  def photo_url
    decorated.photo.convert('-strip').thumb('240x240#').url if decorated.photo_stored?
  end
end
