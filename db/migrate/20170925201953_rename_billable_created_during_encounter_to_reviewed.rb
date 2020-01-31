class RenameBillableCreatedDuringEncounterToReviewed < ActiveRecord::Migration[5.0]
  def change
    rename_column :billables, :created_during_encounter, :reviewed
    change_column_default :billables, :reviewed, true
    Billable.update_all('reviewed = NOT reviewed')
  end
end
