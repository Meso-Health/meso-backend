class MembershipPayment < ApplicationRecord
  belongs_to :household_enrollment_record

  validates :receipt_number, :payment_date, presence: true
  validates :annual_contribution_fee, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :registration_fee, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :qualifying_beneficiaries_fee, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :penalty_fee, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :other_fee, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :card_replacement_fee, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def total
    [
      annual_contribution_fee,
      registration_fee,
      qualifying_beneficiaries_fee,
      card_replacement_fee,
      penalty_fee,
      other_fee
    ].sum
  end
end
