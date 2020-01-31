class ChangeItemIdToStringOnVersions < ActiveRecord::Migration[5.0]
  def change
    change_column :versions, :item_id, :string
  end
end
