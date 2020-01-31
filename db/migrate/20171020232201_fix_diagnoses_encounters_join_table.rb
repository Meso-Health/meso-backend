class FixDiagnosesEncountersJoinTable < ActiveRecord::Migration[5.0]
  def change
    remove_column :diagnoses_encounters, :encounter_id, :integer
    add_column :diagnoses_encounters, :encounter_id, :uuid, null: false
    add_index :diagnoses_encounters, :encounter_id
  end
end
