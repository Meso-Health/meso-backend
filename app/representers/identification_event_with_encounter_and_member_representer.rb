class IdentificationEventWithEncounterAndMemberRepresenter < IdentificationEventRepresenter
  property :encounter, decorator: EncounterRepresenter, writeable: false, render_nil: true
  property :member,
           writeable: false,
           getter: ->(options:, **) { MemberRepresenter.new(member).to_hash(mrn_key: options[:mrn_key]) }
end
