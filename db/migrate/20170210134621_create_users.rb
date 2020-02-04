class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :role, null: false
      t.uuid :comm_care_mobile_worker_id

      t.timestamps
    end
  end
end
