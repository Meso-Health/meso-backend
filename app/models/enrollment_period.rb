class EnrollmentPeriod < ApplicationRecord
  has_many :member_enrollment_records
  has_many :household_enrollment_records
  has_many :membership_payments, through: :household_enrollment_records
  belongs_to :administrative_division

  validates :administrative_division, presence: true
  validate :valid_dates

  scope :active_now, -> { active_at }
  scope :active_at, lambda { |timestamp = Time.zone.now|
    where('start_date <= ? AND end_date >= ?', timestamp, timestamp)
  }
  scope :inactive, -> { where('end_date <= ?', Time.zone.now).order('end_date') }

  def coverage_active?
    coverage_active_at?(Time.zone.now)
  end

  def coverage_active_at?(time)
    (coverage_start_date..coverage_end_date).cover?(time)
  end

  private
  def overlaps?(other_enrollment_period)
    start_date < other_enrollment_period.end_date && other_enrollment_period.start_date < end_date
  end

  def valid_dates
    if start_date.blank?
      errors.add(:start_date, "is missing or invalid")
    elsif end_date.blank?
      errors.add(:end_date, "is missing or invalid")
    elsif coverage_start_date.blank?
      errors.add(:coverage_start_date, "is missing or invalid")
    elsif coverage_end_date.blank?
      errors.add(:coverage_end_date, "is missing or invalid")
    else
      # Start date must be after end date.
      if start_date >= end_date
        errors.add(:end_date, "must be after the start date")
      end
      if start_date > coverage_start_date
        errors.add(:coverage_start_date, "must be equal or after the start date")
      end
      if coverage_start_date >= coverage_end_date
        errors.add(:coverage_end_date, "must be after the coverage start date")
      end
      # This enrollment period must not overlap with any other enrollment period within the same administrative division.
      EnrollmentPeriod.where(administrative_division: administrative_division).where.not(id: id).each do |enrollment_period|
        if overlaps?(enrollment_period)
          errors.add(:base, "overlaps with EnrollmentPeriod #{enrollment_period.id}")
        end
      end
    end
  end
end
