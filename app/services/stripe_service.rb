class StripeService
  def initiate_transfer!(transfer)
    raise 'Payout already initiated' if transfer.stripe_payout_id.present?

    unless transfer.stripe_transfer_id.present?
      transfer.stripe_account_id = ENV.fetch('STRIPE_ACCOUNT_ID')
      transfer.stripe_transfer_id = Stripe::Transfer.create(
        amount: transfer.amount,
        currency: 'usd',
        destination: transfer.stripe_account_id,
        metadata: {description: transfer.description}
      ).id

      transfer.initiated_at = Time.zone.now
      transfer.save!
    end

    transfer.stripe_payout_id = Stripe::Payout.create({
      amount: transfer.amount,
      currency: 'usd',
      description: transfer.description,
      statement_descriptor: "Watsi Coverage ##{transfer.id}"
    },{
      'Stripe-Account' => transfer.stripe_account_id
    }).id

    transfer.save!
  end
end
