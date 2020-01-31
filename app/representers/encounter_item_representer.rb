class EncounterItemRepresenter < ApplicationRepresenter
  property :id, skip_parse: ->(**) { persisted? }
  property :encounter_id, writeable: false
  property :quantity
  property :price_schedule_id
  property :price_schedule_issued
  property :stockout
  property :surgical_score

  property :lab_result,
    decorator: LabResultRepresenter,
    instance: ->(represented:, fragment:, **) { 
      LabResult.find_by(id: fragment['id']) || LabResult.new(encounter_item: represented) 
    }
end
