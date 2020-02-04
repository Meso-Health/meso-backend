class AddInvalidAttributesFieldToEnrollmentRecords < ActiveRecord::Migration[5.0]
  def change
    add_column :member_enrollment_records, :invalid_attributes, :jsonb, default: {}, null: false
    add_column :household_enrollment_records, :invalid_attributes, :jsonb, default: {}, null: false
  end
end
