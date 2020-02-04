class DropEnrollmentRecord < ActiveRecord::Migration[5.0]
  def change
    remove_foreign_key :enrollment_records, :users
    remove_foreign_key :households, :enrollment_records
    remove_foreign_key :members, :enrollment_records

    drop_table :enrollment_records

    remove_column :members, :enrollment_record_id, :uuid
    remove_column :members, :enrollment_record_member_number, :integer
    remove_column :households, :enrollment_record_id, :uuid
  end
end
