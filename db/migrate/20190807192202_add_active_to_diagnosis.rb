class AddActiveToDiagnosis < ActiveRecord::Migration[5.0]
  def change
    add_column :diagnoses, :active, :boolean, default: true, null: false
  end
end
