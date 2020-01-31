class AddRenewalFlagToHouseholdEnrollmentRecord < ActiveRecord::Migration[5.0]
  def change
    add_column :household_enrollment_records, :renewal, :boolean, null: false, default: false
  end
end
