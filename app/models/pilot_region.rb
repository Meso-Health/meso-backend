class PilotRegion < ApplicationRecord
  belongs_to :administrative_division

  validates :administrative_division, presence: true, uniqueness: true
end
