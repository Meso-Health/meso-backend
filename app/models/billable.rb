class Billable < ApplicationRecord
  self.inheritance_column = nil
  TYPES = %w[drug lab service supply vaccine unspecified imaging surgery procedure bed_day]
  ACCOUNTING_GROUP_NAMES = %w[drug_and_supply lab surgery card_and_consultation bed_day_and_food other_services imaging capitation]

  has_many :encounter_items, dependent: :destroy
  has_many :price_schedules

  validates :type, inclusion: {in: TYPES}
  validates :type, inclusion: {in: ['lab']}, if: :requires_lab_result?
  validates :accounting_group, allow_blank: true, inclusion: {in: ACCOUNTING_GROUP_NAMES}
  validates :name, presence: true
  validates :active, inclusion: {in: [true, false]}
  validates :reviewed, inclusion: {in: [true, false]}

  scope :active, -> { where(active: true) }

  def active_price_schedule_for_provider(provider_id)
    self.price_schedules
      .select { |price_schedule| price_schedule.provider_id == provider_id }
      .sort_by(&:issued_at)
      .last
  end
end
