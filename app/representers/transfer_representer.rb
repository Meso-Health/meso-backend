class TransferRepresenter < ApplicationRepresenter
  property :id, skip_parse: ->(**) { persisted? }
  property :amount
  property :description
  property :stripe_account_id, writeable: false
  property :stripe_transfer_id, writeable: false
  property :stripe_payout_id, writeable: false
  property :user_id, writeable: false
end
