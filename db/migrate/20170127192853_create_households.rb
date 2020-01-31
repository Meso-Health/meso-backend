class CreateHouseholds < ActiveRecord::Migration[5.0]
  def change
    create_table :households, id: :uuid, default: "gen_random_uuid()" do |t|
      t.string :photo_uid, null: false
      t.string :photo_name, null: false
      t.decimal :latitude, null: false, precision: 10, scale: 6
      t.decimal :longitude, null: false, precision: 10, scale: 6
      t.boolean :absentee, null: false, default: false
      t.references :enrollment_record, type: :uuid, foreign_key: true

      t.timestamps
    end
  end
end
