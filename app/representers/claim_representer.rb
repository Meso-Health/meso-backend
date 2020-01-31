class ClaimRepresenter < ApplicationRepresenter
  property :id, writeable: false
  property :last_submitted_at, writeable: false, render_nil: true
  property :originally_submitted_at, writeable: false, render_nil: true
  collection :encounters,
             writeable: false,
             getter: ->(options:, **) { EncounterWithMemberRepresenter.for_collection.new(encounters).to_hash(mrn_key: options[:mrn_key]) }
end
