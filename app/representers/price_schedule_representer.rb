class PriceScheduleRepresenter < ApplicationRepresenter
  property :id, skip_parse: ->(**) { persisted? }
  property :price, skip_parse: ->(**) { persisted? }
  property :issued_at, skip_parse: ->(**) { persisted? }
  property :billable_id, skip_parse: ->(**) { persisted? }
  property :provider_id, skip_parse: ->(**) { persisted? }
  property :previous_price_schedule_id, skip_parse: ->(**) { persisted? }, render_nil: true
end
