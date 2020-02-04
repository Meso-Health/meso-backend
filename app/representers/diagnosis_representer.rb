class DiagnosisRepresenter < ApplicationRepresenter
  property :id
  property :description
  property :icd_10_codes, render_nil: true
  property :search_aliases, render_nil: true
  property :active, writeable: false
end
