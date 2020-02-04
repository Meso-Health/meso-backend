class UserRepresenter < ApplicationRepresenter
  property :id, writeable: false
  property :created_at, writeable: false
  property :name
  property :username
  property :role, skip_parse: ->(**) { persisted? }
  property :provider_id, skip_parse: ->(**) { persisted? }
  property :provider_type, getter: -> (**) { provider.try(:provider_type) }, writeable: false
  property :administrative_division_id, skip_parse: ->(**) { persisted? }, render_nil: true
  property :password, readable: false
  property :added_by, getter: -> (**) { added_by.try(:name) }, writeable: false, render_nil: true
  property :security_pin, getter: -> (**) { provider.try(:security_pin) }, writeable: false, render_nil: true
  property :adjudication_limit, render_nil: true
end
