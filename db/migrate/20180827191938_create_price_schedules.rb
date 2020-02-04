class CreatePriceSchedules < ActiveRecord::Migration[5.0]
  def change
    create_table :price_schedules, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.references :provider, foreign_key: true, null: false
      t.references :billable, foreign_key: true, type: :uuid, null: false
      t.datetime :issued_at, null: false
      t.integer :price, null: false
      t.references :previous_price_schedule, foreign_key: { to_table: :price_schedules }, type: :uuid

      t.timestamps
    end
  end
end
