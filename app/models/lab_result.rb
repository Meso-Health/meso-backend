class LabResult < ApplicationRecord
  RESULTS = %w[positive negative unspecified]

  belongs_to :encounter_item

  validates :result, inclusion: {in: RESULTS}
  validates_associated :encounter_item
end
