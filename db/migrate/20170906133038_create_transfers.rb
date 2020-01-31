class CreateTransfers < ActiveRecord::Migration[5.0]
  def change
    create_table :transfers do |t|
      t.string :description
      t.integer :amount, null: false
      t.string :stripe_account_id, null: false
      t.string :stripe_transfer_id, null: false
      t.string :stripe_payout_id
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
