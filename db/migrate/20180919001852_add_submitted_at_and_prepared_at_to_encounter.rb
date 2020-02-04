class AddSubmittedAtAndPreparedAtToEncounter < ActiveRecord::Migration[5.0]
  def up
    add_column :encounters, :submitted_at, :date
    add_column :encounters, :prepared_at, :date
  end

  def down
    remove_column :encounters, :submitted_at
    remove_column :encounters, :prepared_at
  end
end
