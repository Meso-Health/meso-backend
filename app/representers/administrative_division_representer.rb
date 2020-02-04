class AdministrativeDivisionRepresenter < ApplicationRepresenter
  property :id
  property :name
  property :level
  property :code, render_nil: true
  property :parent_id, render_nil: true
end
