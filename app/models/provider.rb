class Provider < ApplicationRecord
  belongs_to :administrative_division
  belongs_to :diagnoses_group, optional: true
  has_many :diagnoses, through: :diagnoses_group
  has_many :identification_events
  has_many :encounters
  has_many :encounter_items, through: :encounters
  has_many :users
  has_many :payments
  has_many :price_schedules
  has_many :billables, through: :price_schedules
  has_many :reimbursements
  has_many :households, through: :members

  validates :name, presence: true
end
