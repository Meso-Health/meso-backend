class AddEnrolledByToEnrollmentRecord < ActiveRecord::Migration[5.0]
  def change
    add_reference :enrollment_records, :user, foreign_key: :true, null: false
  end
end
