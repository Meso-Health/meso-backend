class Household < ApplicationRecord
  include HasAttachment

  belongs_to :administrative_division, optional: true

  has_many :household_enrollment_records
  has_many :members
  has_many :member_enrollment_records, through: :members
  has_many :membership_payments, through: :household_enrollment_records

  has_attachment :photo

  validates :latitude, numericality: true, allow_nil: true
  validates :longitude, numericality: true, allow_nil: true

  def head_of_household
    members.where(relationship_to_head: 'SELF').order('created_at').first
  end

  def merge!(other, attributes_to_overwrite = [])
    transaction do
      # depend on these SELECT queries in the transaction by reloading them
      self.reload
      other.reload

      attributes_to_overwrite.each do |attribute|
        self[attribute] = other[attribute]
      end

      self.members << other.members
      self.merged_from_household_id = other.id

      save!
      other.destroy!
    end

    self
  end

  def assigned_membership_numbers?
    self.members.map(&:membership_number).compact.any?
  end

  def most_recent_enrollment_record
    self.household_enrollment_records.sort_by(&:enrolled_at).last
  end

  def needs_renewal?(most_recent_enrollment_period_id)
    return nil unless most_recent_enrollment_period_id.present?
    most_recent_enrollment_record&.enrollment_period_id != most_recent_enrollment_period_id
  end
end
