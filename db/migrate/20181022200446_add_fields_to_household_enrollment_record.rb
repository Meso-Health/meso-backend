class AddFieldsToHouseholdEnrollmentRecord < ActiveRecord::Migration[5.0]
  def change
    change_table :household_enrollment_records do |t|
      t.boolean :paying, null: false, default: false
      t.references :membership_payment, foreign_key: true, type: :uuid
    end
  end
end
