class AddEnrollmentRecordMemberNumberToMember < ActiveRecord::Migration[5.0]
  def change
    add_column :members, :enrollment_record_member_number, :integer
  end
end
