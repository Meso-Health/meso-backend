class RemovePriceFromBillable < ActiveRecord::Migration[5.0]
  def change
    remove_column :billables, :price, :integer
  end
end
