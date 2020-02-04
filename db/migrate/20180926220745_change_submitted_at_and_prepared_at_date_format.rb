class ChangeSubmittedAtAndPreparedAtDateFormat < ActiveRecord::Migration[5.0]
  def up
    change_column :encounters, :submitted_at, :datetime
    change_column :encounters, :prepared_at, :datetime
  end

  def down
    change_column :encounters, :submitted_at, :date
    change_column :encounters, :prepared_at, :date
  end
end
