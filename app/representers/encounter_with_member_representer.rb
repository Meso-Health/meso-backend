class EncounterWithMemberRepresenter < EncounterRepresenter
  property :member,
           writeable: false,
           render_nil: true,
           getter: ->(options:, **) { MemberRepresenter.new(member).to_hash( mrn_key: options[:mrn_key]) }
end
