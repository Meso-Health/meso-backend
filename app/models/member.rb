class Member < ApplicationRecord
  PREFERRED_LANGUAGE_CHOICES = %w[rutooro rukiga kinyarwanda english ruganda runyankole other]
  UNPAID_ARCHIVED_REASON = 'UNPAID'

  include HasAttachment

  belongs_to :card, optional: true
  belongs_to :household, optional: true
  belongs_to :original_member, class_name: 'Member', optional: true, inverse_of: :duplicate_members
  has_many :household_enrollment_records, through: :household
  has_one :member_enrollment_record
  has_many :identification_events, dependent: :destroy
  has_many :encounters, dependent: :destroy
  has_many :duplicate_members, class_name: 'Member', foreign_key: 'original_member_id', inverse_of: :original_member, dependent: :destroy

  has_attachment :photo

  validates :card_id,
    presence: true,
    uniqueness: true,
    format: { with: CardIdGenerator::FORMAT_REGEX, message: "does not follow the Meso Card ID format" },
    allow_nil: true
  validates :enrolled_at, presence: true
  validates :full_name, presence: true
  validates :gender, inclusion: {in: %w[M F]}
  validates :birthdate, presence: true
  validates :birthdate_accuracy, inclusion: {in: %w[Y M D]}
  validates :preferred_language_other, presence: true, if: -> (m) { m.preferred_language == 'other' }
  validates :preferred_language, inclusion: {in: PREFERRED_LANGUAGE_CHOICES}, allow_nil: true

  after_update :revoke_previous_card
  after_destroy :revoke_card

  scope :unarchived, -> { where(archived_at: nil) }
  scope :filter_with_params, -> (params) {
    where(id: params[:member_id])
      .or(where(membership_number: params[:membership_number]).where.not(membership_number: nil))
      .or(where(card_id: params[:card_id]).where.not(card_id: nil))
      .or(where('medical_record_numbers @> ?', {"#{params[:mrn_key]&.to_s}": params[:medical_record_number]&.to_s}.to_json))
  }

  scope :in_administrative_division, -> (administrative_division) {
    where(household: Household.where(administrative_division_id: administrative_division))
  }
  scope :fuzzy_matching_name, -> (name) {
    where("levenshtein(full_name, '#{name}') <= 11").order("levenshtein(full_name, '#{name}')")
  }
  # TODO: convert dates to application timezone (unless we get rid of this code altogether)
  scope :active_at, lambda { |timestamp = Time.zone.now|
    left_outer_joins(household: [household_enrollment_records: :enrollment_period])
      .where(
        "members.household_id IS NOT NULL
          AND (members.archived_at IS NULL OR members.archived_at >= ?)
          AND EXISTS (
            #{HouseholdEnrollmentRecord.joins(:enrollment_period).where('household_enrollment_records.household_id = households.id')
                         .where('household_enrollment_records.enrolled_at <= ?')
                         .where('? BETWEEN enrollment_periods.coverage_start_date AND enrollment_periods.coverage_end_date')
                         .to_sql}
          )", timestamp, timestamp, timestamp)
      .distinct
  }

  def absentee?
    photo_id.blank? || (age >= 6 && fingerprints_guid.blank?)
  end

  def medical_record_number_from_key(mrn_key)
    medical_record_numbers && medical_record_numbers[mrn_key&.to_s]
  end

  def age
    today = Time.zone.today

    age = today.year - birthdate.year
    return age if birthdate_accuracy == 'Y'

    if today.month < birthdate.month
      return age - 1
    end

    if birthdate_accuracy == 'D'
      if today.month == birthdate.month && today.day < birthdate.day
        return age - 1
      end
    end

    age
  end

  def enrolled?
    household_id.present?
  end

  def duplicate?
    original_member.present?
  end

  def has_duplicates?
    duplicate_members.exists?
  end

  def archived?
    archived_at.present?
  end

  def unpaid?
    archived? && archived_reason == UNPAID_ARCHIVED_REASON
  end

  def active?
    active_at?(Time.zone.now)
  end

  def active_at?(time)
    # important: this does not take into consideration cases where the member was already archived at the time
    not_archived_at_time = archived_at.blank? || archived_at >= time

    # intentionally using the Ruby `select` instead of the ActiveRecord `where` to avoid forcing
    # a DB query as household_enrollment_records are `include`d on the source Member data
    household_enrollment_records_at_time = household_enrollment_records.select { |her| her.enrolled_at <= time }
    enrolled? && not_archived_at_time && household_enrollment_records_at_time.any? { |her| her.enrollment_period.coverage_active_at?(time) }
  end

  def inactive?
    inactive_at?(Time.zone.now)
  end

  def inactive_at?(time)
    enrolled? && !active_at?(time)
  end

  def archive!(archived_reason)
    self.archived_at = Time.zone.now
    self.archived_reason = archived_reason
    save!
  end

  def archive_as_duplicate_of!(original_member)
    return nil if original_member.nil?

    self.archive!('OTHER') # TODO: standardize archive reasons and make this `DUPLICATE`
    self.original_member = original_member
    save!

    original_member
  end

  def needs_renewal?(most_recent_enrollment_period_id)
    return nil unless most_recent_enrollment_period_id.present?
    return true if unpaid?
    household&.needs_renewal?(most_recent_enrollment_period_id)
  end

  def head_of_household?
    relationship_to_head == 'SELF'
  end

  def coverage_end_date
    household_enrollment_records.map {|her| her.enrollment_period.coverage_end_date }.sort.last
  end

  def renewed_at
    household_enrollment_records.map(&:enrolled_at).sort.last
  end

  def set_medical_record_number(nullable_provider_id, medical_record_number)
    if medical_record_number.present?
      provider_id_key = nullable_provider_id || 'primary'
      self.medical_record_numbers = self.medical_record_numbers.merge(
        "#{provider_id_key}": medical_record_number
      )
    end
  end

  def set_card_id_to_nil_if_invalid
    if self.card_id.present?
      card = Card.find_by_id(self.card_id)
      if card.blank?
        self.card_id = nil
      elsif (card.member.present? && card.member.id != self.id)
        self.card_id = nil
      end
    end
  end

  private
  def revoke_previous_card
    revoke_card(attribute_before_last_save('card_id')) if saved_change_to_attribute?('card_id')
  end

  def revoke_card(id = self.card_id, reason = nil)
    Card.find(id).revoke!(reason) if id.present?
  end
end
