class ChangePaymentStripeTransferIdToArray < ActiveRecord::Migration[5.0]
  def change
    remove_column :payments, :stripe_transfer_id, :string, null: false
    add_column :payments, :stripe_transfer_ids, :string, array: true, default: [], null: false
  end
end
