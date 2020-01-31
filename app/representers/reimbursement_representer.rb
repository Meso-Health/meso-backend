class ReimbursementRepresenter < ApplicationRepresenter
  property :id, writeable: false
  property :created_at, writeable: false
  property :updated_at
  property :user_id
  property :provider_id
  property :total
  property :completed_at, render_nil: true
  property :payment_date, render_nil: true
  property :payment_field, render_nil: true
  property :encounter_ids, writeable: false
  property :claim_count, writeable: false, getter: ->(**) { encounter_ids&.count }
  property :start_date, writeable: false
  property :end_date, writeable: false
end
