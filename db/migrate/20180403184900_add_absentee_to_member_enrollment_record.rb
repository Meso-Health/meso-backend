class AddAbsenteeToMemberEnrollmentRecord < ActiveRecord::Migration[5.0]
  def change
    add_column :member_enrollment_records, :absentee, :boolean
  end
end
