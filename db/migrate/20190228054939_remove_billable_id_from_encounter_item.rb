class RemoveBillableIdFromEncounterItem < ActiveRecord::Migration[5.0]
  def change
    remove_column :encounter_items, :billable_id, :uuid
  end
end
