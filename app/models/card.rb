class Card < ApplicationRecord
  belongs_to :card_batch
  has_one :member

  validates :id,
      presence: true,
      uniqueness: true,
      format: { with: CardIdGenerator::FORMAT_REGEX, message: "does not follow the UHP ID format" }

  scope :unassigned, -> { includes(:member).where(members: { card_id: nil }) }

  def revoked?
    revoked_at?
  end

  def revoke!(reason = nil)
    unless revoked?
      update!(revoked_at: Time.zone.now, revocation_reason: reason)
      member.update!(card_id: nil) if member.present?
    end
  end

  def format_with_spaces
    [id.slice(0, 3), id.slice(3, 3), id.slice(6, 3)].join(' ')
  end
end
