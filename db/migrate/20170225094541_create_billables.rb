class CreateBillables < ActiveRecord::Migration[5.0]
  def change
    create_table :billables, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.references :facility, foreign_key: true, null: false
      t.string :type, null: false
      t.string :name, null: false
      t.string :composition
      t.string :unit
      t.string :department
      t.integer :price, null: false
      t.boolean :active, null: false, default: true
      t.boolean :manually_added, null: false, default: false

      t.timestamps
    end
  end
end
