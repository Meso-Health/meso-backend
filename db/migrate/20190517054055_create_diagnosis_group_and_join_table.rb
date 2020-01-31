class CreateDiagnosisGroupAndJoinTable < ActiveRecord::Migration[5.0]
  def change
    create_table :diagnoses_groups do |t|
      t.string :name, null: false
      t.timestamps
    end

    create_join_table :diagnoses_groups, :diagnoses do |t|
      t.index :diagnoses_group_id
      t.index :diagnosis_id
    end
  end
end
