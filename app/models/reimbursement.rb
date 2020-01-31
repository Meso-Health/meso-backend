class Reimbursement < ApplicationRecord
  belongs_to :provider
  belongs_to :user
  has_many :encounters

  validates :total, presence: true
  validate :payment_fields_all_set_or_all_empty
  validates :encounters, :presence => true

  def editable?
    payment_date.nil? && payment_field.nil? && completed_at.nil?
  end

  scope :paid, -> { where.not(payment_date: nil) }

  def start_date
    encounters.order('adjudicated_at').first.adjudicated_at.to_date
  end

  def end_date
    encounters.order('adjudicated_at').last.adjudicated_at.to_date
  end

  private
  def payment_fields_all_set_or_all_empty
    errors.add(:base, 'payment_date, payment_field, completed_at must either all be set, or all be nil.') unless (
      (payment_date.present? && payment_field.present? && completed_at.present?) ||
      (payment_date.nil? && payment_field.nil? && completed_at.nil?)
    )
  end
end
