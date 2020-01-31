class IdentificationEvent < ApplicationRecord
  SEARCH_METHODS = %w[scan_barcode search_card_id search_name search_membership_number manual_entry through_household].freeze
  CLINIC_NUMBER_TYPES = %w[opd delivery].freeze
  DISMISSAL_REASONS = {
    patient_on_other_phone: 'The patient was checked in on the other phone',
    accidental_identification: 'The patient was accidentally identified',
    patient_left_before_care: 'The patient was identified but left before receiving care',
    patient_left_after_care: 'The patient was identified but left, without following up, after receiving care',
    duplicate: 'This was a duplicate of another identification'
  }.stringify_keys.freeze

  belongs_to :provider
  belongs_to :member
  belongs_to :user
  belongs_to :through_member, optional: true, class_name: 'Member'
  has_one :encounter, dependent: :destroy

  validates :occurred_at, presence: true
  # validates :search_method, inclusion: {in: SEARCH_METHODS}
  validates :accepted, inclusion: { in: [true, false] }, allow_nil: true
  validates :photo_verified, inclusion: { in: [true, false] }, allow_nil: true
  validates :through_member, presence: true, if: ->(i) { i.search_method == 'through_household' }
  validates :clinic_number_type, inclusion: { in: CLINIC_NUMBER_TYPES }, allow_nil: true

  # cannot name "open" since it would override an existing private method
  scope :is_open, -> { joins(:encounter).where(dismissed: false).where(encounters: { submission_state: 'started' }) }

  def dismiss_as_duplicate!
    self.dismissed = true
    self.dismissal_reason = 'duplicate'
    save!
  end

  def dismissed?
    dismissed == true
  end
end
