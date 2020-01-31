class CreatePayments < ActiveRecord::Migration[5.0]
  def change
    create_table :payments do |t|
      t.references :provider, foreign_key: true, null: false
      t.integer :amount, null: false
      t.string :type, null: false
      t.date :effective_date, null: false
      t.timestamp :paid_at, null: false
      t.string :stripe_transfer_id, null: false
      t.jsonb :details, default: {}, null: false

      t.timestamps
    end
  end
end
