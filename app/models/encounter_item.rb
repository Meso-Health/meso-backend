class EncounterItem < ApplicationRecord
  belongs_to :encounter
  belongs_to :price_schedule
  has_one :billable, :through => :price_schedule
  has_one :lab_result, dependent: :destroy

  validates :quantity, numericality: {only_integer: true, greater_than: 0}
  validates :surgical_score, allow_blank: true, numericality: {only_integer: true, greater_than: 0, less_than: 6}
  validates_associated :billable

  scope :for_provider, ->(provider) { joins(encounter: :provider).where('encounters.provider_id = ?', provider) }

  def price
    self.stockout ? 0 : self.price_schedule.price * self.quantity
  end
end
