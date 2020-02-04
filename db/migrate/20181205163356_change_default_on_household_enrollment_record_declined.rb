class ChangeDefaultOnHouseholdEnrollmentRecordDeclined < ActiveRecord::Migration[5.0]
  def change
    change_column_default :household_enrollment_records, :declined, false
  end
end
