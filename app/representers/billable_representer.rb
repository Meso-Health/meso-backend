class BillableRepresenter < ApplicationRepresenter
  property :id
  property :type
  property :name
  property :composition, render_nil: true
  property :unit, render_nil: true
  property :requires_lab_result, writeable: false
  property :active, writeable: false
  property :reviewed, writeable: false
  property :accounting_group, writeable: false, render_nil: true
end
