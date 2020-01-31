class AddPatientOutcomeToEncounters < ActiveRecord::Migration[5.0]
  def change
    add_column :encounters, :patient_outcome, :string
  end
end
