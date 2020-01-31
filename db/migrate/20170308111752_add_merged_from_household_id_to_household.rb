class AddMergedFromHouseholdIdToHousehold < ActiveRecord::Migration[5.0]
  def change
    add_column :households, :merged_from_household_id, :uuid
  end
end
