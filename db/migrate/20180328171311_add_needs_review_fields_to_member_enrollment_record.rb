class AddNeedsReviewFieldsToMemberEnrollmentRecord < ActiveRecord::Migration[5.0]
  def change
    add_column :member_enrollment_records, :note, :text
    add_column :member_enrollment_records, :needs_review, :boolean, null: false, default: false
  end
end
