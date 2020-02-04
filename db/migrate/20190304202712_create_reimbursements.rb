class CreateReimbursements < ActiveRecord::Migration[5.0]
  def change
    create_table :reimbursements, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.references :user, null: false
      t.references :provider, null: false
      t.string :total, null: false
      t.timestamp :completed_at
      t.string :transfer_number
      t.date :transfer_date
      t.string :receipt_number
      t.date :receipt_date
      t.timestamps
    end
  end
end
