class CreateMembershipPayment < ActiveRecord::Migration[5.0]
  def change
    create_table :membership_payments, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.string :receipt_number, null: false
      t.date :payment_date, null: false
      t.integer :total, null: false

      t.timestamps
    end
  end
end
