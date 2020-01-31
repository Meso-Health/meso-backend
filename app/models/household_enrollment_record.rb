class HouseholdEnrollmentRecord < ApplicationRecord
  include HandlesInvalidAttributes

  belongs_to :user
  belongs_to :household, autosave: true
  belongs_to :enrollment_period
  belongs_to :administrative_division, optional: true
  has_many :membership_payments
  has_many :members, through: :household

  def sum_fee_of_type(field)
    self.membership_payments.map(&field).sum / 100.00
  end

  def total_payments
    self.membership_payments.map(&:total).sum / 100.0
  end
end
