class CreateJoinTablePaymentTransfer < ActiveRecord::Migration[5.0]
  def change
    remove_column :transfers, :payment_id
    create_join_table :payments, :transfers do |t|
      t.index [:payment_id, :transfer_id]
    end
  end
end
