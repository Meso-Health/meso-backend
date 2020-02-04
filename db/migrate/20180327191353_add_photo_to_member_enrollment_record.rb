class AddPhotoToMemberEnrollmentRecord < ActiveRecord::Migration[5.0]
  def change
    add_column :member_enrollment_records, :photo_id, :string, limit: 32, null: true
    add_foreign_key :member_enrollment_records, :attachments, column: :photo_id
  end
end
