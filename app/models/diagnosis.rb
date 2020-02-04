class Diagnosis < ApplicationRecord
  has_and_belongs_to_many :encounters
  has_and_belongs_to_many :diagnoses_groups

  validates :description, presence: true

  scope :active, -> { where(active: true) }
end
