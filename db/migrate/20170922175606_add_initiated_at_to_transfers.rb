class AddInitiatedAtToTransfers < ActiveRecord::Migration[5.0]
  def change
    add_column :transfers, :initiated_at, :datetime
    Transfer.update_all('initiated_at = created_at')
    change_column_null :transfers, :initiated_at, false
  end
end
