class RenameManuallyAddedToCreatedDuringEncounterOnBillable < ActiveRecord::Migration[5.0]
  def change
    rename_column :billables, :manually_added, :created_during_encounter
  end
end
