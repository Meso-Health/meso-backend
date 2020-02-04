class MemberRepresenter < ApplicationRepresenter
  property :id, skip_parse: ->(**) { persisted? }
  property :created_at, writeable: false
  property :updated_at, writeable: false
  property :enrolled_at, skip_parse: ->(**) { persisted? }

  property :absentee, getter: ->(**) { absentee? }, writeable: false

  property :card_id, render_nil: true
  property :full_name
  property :gender
  property :age, writeable: false
  property :birthdate
  property :birthdate_accuracy
  property :phone_number, render_nil: true
  property :fingerprints_guid, render_nil: true
  property :preferred_language
  property :preferred_language_other
  property :membership_number, render_nil: true

  property :medical_record_number,
    getter: ->(options:, **) {
      medical_record_number_from_key(options[:mrn_key])
    },
    writeable: false,
    render_nil: true

  # This field is meant to be passed in addition to the medical_record_number field.
  # It is an incremental change to begin to better support provider-specific MRNs.
  property :medical_record_numbers,
    writeable: false,
    render_nil: true

  property :profession, render_nil: true
  property :relationship_to_head, render_nil: true
  property :archived_at, render_nil: true
  property :archived_reason, render_nil: true
  property :household_id, render_nil: true, skip_parse: ->(**) { persisted? }
  property :administrative_division_id, getter: ->(**) { household&.administrative_division_id }, render_nil: true, writeable: false

  property :photo, readable: false
  property :photo_url, exec_context: :decorator, writeable: false

  # helpers for computing membership status on clients
  property :coverage_end_date,
    getter: ->(**) { coverage_end_date },
    writeable: false,
    render_nil: true
  property :renewed_at,
    getter: ->(**) { renewed_at },
    writeable: false,
    render_nil: true

  # deprecated properties - can be removed once all clients are on updated code
  property :needs_renewal,
    getter: ->(options:, **) { needs_renewal?(options[:most_recent_enrollment_period_id]) },
    writeable: false,
    render_nil: true
  property :unpaid, getter: ->(**) { unpaid? }, writeable: false

  def photo_url
    decorated.photo.convert('-strip').thumb('240x240#').url if decorated.photo_stored?
  end
end
