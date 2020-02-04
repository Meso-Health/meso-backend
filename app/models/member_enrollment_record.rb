class MemberEnrollmentRecord < ApplicationRecord
  include HasAttachment
  include HandlesInvalidAttributes

  belongs_to :user
  belongs_to :member, autosave: true
  belongs_to :enrollment_period

  has_attachment :photo

  validates :note, absence: true, unless: :needs_review?
  # putting this validation on MemberEnrollmentRecord so that we can catch invalid card IDs at
  # the application level instead of at the DB level via a foreign key violation so that the
  # model still gets saved and the card ID is added to the invalid_attributes - and we apply the
  # validation to this model instead of the Member model because it is expensive (due to having
  # to query the DB), so we do not want to handle the overhead on every Member save
  validate :card_id_is_available, if: ->(record) { record.member&.card_id? }

  after_create :issue_membership_number!, if: ->() { ActiveModel::Type::Boolean.new.cast(ENV['ENABLE_AUTO_MEMBERSHIP_NUMBER_GENERATION']) }

  def card_id_is_available
    card_id = self.member.card_id
    card = Card.find_by_id(card_id)
    if card.nil?
      errors.add(:base, :invalid, value: card_id, message: 'card does not exist')
      self.member.card_id = nil
    elsif (card.member.present? && card.member != self.member)
      errors.add(:base, :invalid, value: card_id, message: 'card is already assigned')
      self.member.card_id = nil
    end
  end

  private
  def issue_membership_number!
    MembershipNumberService.new.issue_membership_number!(self) unless self.member.membership_number?
  end
end
