class AddStockoutToEncounterItem < ActiveRecord::Migration[5.0]
  def change
    add_column :encounter_items, :stockout, :boolean, null: false, default: false
  end
end
