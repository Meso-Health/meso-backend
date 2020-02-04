class AddEnrollmentRecordIdToMember < ActiveRecord::Migration[5.0]
  def change
    add_reference :members, :enrollment_record, type: :uuid, foreign_key: true
  end
end
