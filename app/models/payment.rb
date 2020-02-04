class Payment < ApplicationRecord
  self.inheritance_column = nil
  TYPES = %w[capitation_fee fee_for_service]
  CAPITATION_FEE_DETAILS = %w[fee_per_member member_count]

  belongs_to :provider
  has_and_belongs_to_many :transfers

  validates :amount, presence: true, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :type, inclusion: {in: TYPES}
  validates :effective_date, presence: true, uniqueness: {scope: [:provider, :type]}
  validate :effective_date_is_first_of_month
  validates :paid_at, presence: true
  validates :transfers, presence: true
  validate :details_for_type

  scope :capitation_fee, -> { where(type: :capitation_fee) }
  scope :fee_for_service, -> { where(type: :fee_for_service) }

  private
  def effective_date_is_first_of_month
    if effective_date.present? && effective_date.at_beginning_of_month != effective_date
      errors.add(:effective_date, :invalid, value: effective_date,
            message: 'must be on the first of the month')
    end
  end

  def details_for_type
    missing_keys = []

    if type == 'capitation_fee'
      missing_keys = CAPITATION_FEE_DETAILS - details.keys
    end

    unless missing_keys.empty?
      errors.add(:details, :blank, value: details, message: "must contain required keys; missing keys are #{missing_keys.to_sentence}")
    end
  end
end
