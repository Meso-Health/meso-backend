# This representer is for POSTing a new household and GETing household by membership_number

class HouseholdRepresenter < ApplicationRepresenter
  property :id
  property :enrolled_at # TODO: We don't actually need this and get rid of this field in the schema
  property :administrative_division_id, skip_parse: ->(**) { persisted? }
  property :address, render_nil: true

  property :members,
    getter: ->(options:, **) {
      MemberRepresenter.for_collection.new(members).to_hash(
        mrn_key: options[:mrn_key],
      )
    },
    writeable: false
end
