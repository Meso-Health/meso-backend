class Transfer < ApplicationRecord
  belongs_to :user
  has_and_belongs_to_many :payments

  validates :amount, numericality: {only_integer: true, greater_than: 0}
  validates :stripe_account_id, presence: true
  validates :stripe_transfer_id, presence: true
  validates :initiated_at, presence: true
end
