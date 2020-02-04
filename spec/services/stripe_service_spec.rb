require 'rails_helper'

RSpec.describe StripeService do
  describe '#initiate_transfer!' do
    let(:stripe_transfer_response) { double(id: 'tr_bf1pgbjgdk1jlr') }
    let(:stripe_payout_response) { double(id: 'po_u1a6fa2czmm9s4zljfpfl6fy') }

    context 'not initiated' do
      let(:transfer) do
        build(:transfer,
          id: 4321,
          stripe_account_id: nil,
          stripe_transfer_id: nil,
          stripe_payout_id: nil,
          initiated_at: nil
        )
      end

      before do
        allow(Stripe::Transfer).to receive(:create).with({
          amount: transfer.amount,
          currency: 'usd',
          destination: 'acct_1AUIf0LVHcdVuufE',
          metadata: {description: transfer.description}
        }).and_return(stripe_transfer_response)

        allow(Stripe::Payout).to receive(:create).with({
          amount: transfer.amount,
          currency: 'usd',
          description: transfer.description,
          statement_descriptor: "Watsi Coverage #4321"
        },{
          'Stripe-Account' => 'acct_1AUIf0LVHcdVuufE'
        }).and_return(stripe_payout_response)
      end

      it 'initiates a Stripe transfer and payout' do
        subject.initiate_transfer!(transfer)
        expect(transfer.stripe_account_id).to eq 'acct_1AUIf0LVHcdVuufE'
        expect(transfer.stripe_transfer_id).to eq 'tr_bf1pgbjgdk1jlr'
        expect(transfer.stripe_payout_id).to eq 'po_u1a6fa2czmm9s4zljfpfl6fy'
      end
    end

    context 'transfer initiated' do
      let(:transfer) { create(:transfer, :payout_failed) }

      before do
        allow(Stripe::Payout).to receive(:create).with({
          amount: transfer.amount,
          currency: 'usd',
          description: transfer.description,
          statement_descriptor: "Watsi Coverage ##{transfer.id}"
        },{
          'Stripe-Account' => transfer.stripe_account_id
        }).and_return(stripe_payout_response)
      end

      it 'initiates a Stripe payout' do
        subject.initiate_transfer!(transfer)
        expect(transfer.stripe_account_id).to eq transfer.stripe_account_id
        expect(transfer.stripe_transfer_id).to eq transfer.stripe_transfer_id
        expect(transfer.stripe_payout_id).to eq 'po_u1a6fa2czmm9s4zljfpfl6fy'
      end
    end

    context 'payout initiated' do
      let(:transfer) { build(:transfer) }

      it 'raises an error' do
        expect { subject.initiate_transfer!(transfer) }.to raise_error('Payout already initiated')
      end
    end
  end
end
