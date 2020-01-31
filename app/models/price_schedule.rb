class PriceSchedule < ApplicationRecord
  belongs_to :provider
  belongs_to :billable
  belongs_to :previous_price_schedule, class_name: 'PriceSchedule', optional: true

  validates :price, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :billable, presence: true
  validates :previous_price_schedule_id, presence: true, if: :billable_has_price_schedule?

  # A price schedule is considered active if the billable is active AND 
  # it is the latest issued price for that provider / billable combination.
  scope :active, -> { 
    includes(:billable).
    where(billables: { active: true }).
    select("DISTINCT ON (billable_id, provider_id) *").
    order("billable_id, provider_id, issued_at DESC")
  }

  def billable_has_price_schedule?
    PriceSchedule.where(billable_id: billable_id, provider_id: provider_id).exists?
  end
end
