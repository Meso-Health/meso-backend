class AddSurgicalScoreToEncounterItem < ActiveRecord::Migration[5.1]
  def change
    add_column :encounter_items, :surgical_score, :integer
  end
end
