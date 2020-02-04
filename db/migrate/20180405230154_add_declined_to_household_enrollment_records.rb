class AddDeclinedToHouseholdEnrollmentRecords < ActiveRecord::Migration[5.0]
  def change
    add_column :household_enrollment_records, :declined, :boolean, null: false
  end
end
