class RemoveParentIdFromDiagnoses < ActiveRecord::Migration[5.0]
  def change
    remove_column :diagnoses, :parent_id, :integer
  end
end
