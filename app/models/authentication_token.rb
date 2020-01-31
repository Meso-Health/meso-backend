class AuthenticationToken < ApplicationRecord
  DEFAULT_TTL = 2.weeks

  belongs_to :user

  validates :id, presence: true, length: {is: 8}
  validates :secret_digest, presence: true, length: {is: 64}

  before_create :set_expiration

  def expired?
    expires_at <= Time.zone.now
  end

  def revoked?
    revoked_at?
  end

  def revoke!
    update!(revoked_at: Time.zone.now) unless revoked?
  end

  private
  def set_expiration
    self.expires_at = created_at + DEFAULT_TTL unless self.expires_at.present?
  end
end
