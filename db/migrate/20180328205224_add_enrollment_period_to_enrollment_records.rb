class AddEnrollmentPeriodToEnrollmentRecords < ActiveRecord::Migration[5.0]
  def change
    add_reference :member_enrollment_records, :enrollment_period, foreign_key: true, null: false
    add_reference :household_enrollment_records, :enrollment_period, foreign_key: true, null: false
  end
end
