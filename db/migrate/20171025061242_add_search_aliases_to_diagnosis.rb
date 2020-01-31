class AddSearchAliasesToDiagnosis < ActiveRecord::Migration[5.0]
  def change
    add_column :diagnoses, :search_aliases, :string, array: true, null: false, default: []
  end
end
