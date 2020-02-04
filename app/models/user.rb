class User < ApplicationRecord

  ROLES = %w[
    system_admin
    payer_admin
    adjudication
    enrollment
    provider_admin
    identification
    submission
  ].freeze

  PROVIDER_ROLES = %w[
    provider_admin
    identification
    submission
  ].freeze

  ENROLLMENT_ROLES = %w[
    enrollment
  ].freeze

  REMIBURSEMENT_PERMITTED_ROLES = %w[
    system_admin
    payer_admin
    adjudication
    provider_admin
  ].freeze

  SYSTEM_ADMIN_ROLES = %w[
    system_admin
  ].freeze

  ADJUDICATION_ROLES = %w[
    payer_admin
    adjudication
  ].freeze

  attribute :username, :username_string

  belongs_to :provider, optional: true
  belongs_to :administrative_division, optional: true
  has_many :authentication_tokens
  has_many :reimbursements

  has_secure_password validations: false

  validate do |record|
    record.errors.add(:password, :blank) unless record.password_digest.present?
  end

  validates :name, presence: true
  validates :username, presence: true, uniqueness: true
  validates :role, inclusion: {in: ROLES}
  validates :password, allow_blank: true, length: 6..ActiveModel::SecurePassword::MAX_PASSWORD_LENGTH_ALLOWED
  validates :provider, presence: true, if: :is_provider_role?
  validates :provider, absence: true, unless: :is_provider_role?
  validates :administrative_division, presence: true, if: :is_enrollment_role?
  validates :administrative_division, absence: true, if: :is_provider_role?
  validates :adjudication_limit, absence: true, if: :cannot_have_adjudication_limit?

  scope :active, -> { where(deleted_at: nil) }

  ROLES.each do |role|
    define_method "#{role}?" do
      self.role == role
    end
  end

  def delete!
    unless deleted?
      update!(deleted_at: Time.zone.now)
      revoke_authentication_tokens
    end
  end

  def deleted?
    deleted_at.present?
  end

  def added_by
    versions.find_by_event('create').try(:user)
  end

  # Based on the user role, this returns which key the MRN is stored under on the member model.
  def mrn_key
    if self.provider_id.present?
      provider_id.to_s
    elsif ENROLLMENT_ROLES.include?(self.role)
      'primary'
    end
  end

  private
  def revoke_authentication_tokens
    self.authentication_tokens.each { |token| token.revoke! }
  end

  def is_provider_role?
    PROVIDER_ROLES.include?(self.role)
  end

  def is_enrollment_role?
    ENROLLMENT_ROLES.include?(self.role)
  end

  def cannot_have_adjudication_limit?
    !ADJUDICATION_ROLES.include?(self.role)
  end
end
