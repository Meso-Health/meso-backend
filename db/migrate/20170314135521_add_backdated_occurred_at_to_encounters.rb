class AddBackdatedOccurredAtToEncounters < ActiveRecord::Migration[5.0]
  def change
    add_column :encounters, :backdated_occurred_at, :boolean, default: false, null: false
  end
end
