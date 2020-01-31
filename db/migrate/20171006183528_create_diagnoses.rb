class CreateDiagnoses < ActiveRecord::Migration[5.0]
  def change
    create_table :diagnoses do |t|
      t.string :description, null: false
      t.string :icd_10_codes, array: true
      t.references :parent, foreign_key: { to_table: :diagnoses }

      t.timestamps
    end

    create_join_table :encounters, :diagnoses do |t|
      t.index :encounter_id
      t.index :diagnosis_id
    end
  end
end
