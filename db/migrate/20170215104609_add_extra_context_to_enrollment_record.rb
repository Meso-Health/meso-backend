class AddExtraContextToEnrollmentRecord < ActiveRecord::Migration[5.0]
  def change
    add_column :enrollment_records, :extra_context, :json, default: {}, null: false
  end
end
