class Referral < ApplicationRecord
  belongs_to :encounter
  has_one :receiving_encounter, class_name: 'Encounter'

  def receiving_encounter_id
    receiving_encounter&.id
  end

  validates :reason, presence: true
end
