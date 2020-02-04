class AddDetailColumnsToMembers < ActiveRecord::Migration[5.0]
  def change
    truncate :members
    change_table :members do |t|
      t.rename :name, :full_name

      t.string :national_id_photo_uid
      t.string :national_id_photo_name
      t.references :household, type: :uuid, foreign_key: true, null: false
      t.string :gender, limit: 1, null: false
      t.uuid :fingerprints_guid, index: {unique: true}
      t.string :phone_number, limit: 10
      t.boolean :absentee, default: false, null: false
      t.string :absence_reason
    end
  end
end
