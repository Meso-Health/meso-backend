class AddPatientExperienceTable < ActiveRecord::Migration[5.1]
  def change
    create_table :patient_experiences do |t|
      t.integer :score, null: false
      t.references :encounter, type: :uuid, foreign_key: true, null: false
      t.timestamps
    end
  end
end
