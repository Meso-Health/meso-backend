class PatientExperience < ApplicationRecord
  belongs_to :encounter
  validates :score, numericality: {only_integer: true, greater_than: 0}
end
