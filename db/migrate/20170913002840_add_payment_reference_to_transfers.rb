class AddPaymentReferenceToTransfers < ActiveRecord::Migration[5.0]
  def change
    remove_column :payments, :stripe_transfer_ids, :string, array: true, default: [], null: false
    add_reference :transfers, :payment, foreign_key: true
  end
end
