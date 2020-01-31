class CreateHouseholdEnrollmentRecords < ActiveRecord::Migration[5.0]
  def change
    create_table :household_enrollment_records, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.datetime :enrolled_at, null: false
      t.references :household, type: :uuid, foreign_key: true, null: false
      t.references :user, foreign_key: true, null: false

      t.timestamps
    end
  end
end
